require 'log4r'
require 'socket'
require 'timeout'

require 'vagrant/util/retryable'

module VagrantPlugins
  module Openstack
    module Action
      class CreateServer
        include Vagrant::Util::Retryable

        def initialize(app, _env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_openstack::action::create_server')
        end

        def call(env)
          @logger.info 'Start create server action'

          nova = env[:openstack_client].nova

          flavor = resolve_flavor(env)
          image = resolve_image(env)
          networks = resolve_networks(env)
          server_id = create_server(env, flavor, image, networks)

          # Store the ID right away so we can track it
          env[:machine].id = server_id

          waiting_for_server_to_be_build(env, server_id)

          floating_ip = resolve_floating_ip(env)
          if floating_ip && !floating_ip.empty?
            @logger.info "Using floating IP #{floating_ip}"
            env[:ui].info(I18n.t('vagrant_openstack.using_floating_ip', floating_ip: floating_ip))
            nova.add_floating_ip(env, server_id, floating_ip)
          end

          unless env[:interrupted]
            # Clear the line one more time so the progress is removed
            env[:ui].clear_line

            # Wait for SSH to become available
            ssh_timeout = env[:machine].provider_config.ssh_timeout
            unless port_open?(env, floating_ip, 22, ssh_timeout)
              env[:ui].error(I18n.t('vagrant_openstack.timeout'))
              fail Errors::SshUnavailable, host: floating_ip, timeout: ssh_timeout
            end

            @logger.info 'The server is ready'
            env[:ui].info(I18n.t('vagrant_openstack.ready'))
          end

          @app.call(env)
        end

        private

        # 1. if floating_ip is set, use it
        # 2. if floating_ip_pool is set
        #    GET v2/{{tenant_id}}/os-floating-ips
        #    If any IP with the same pool is available, use it
        #    Else Allocate a new IP from the pool
        #       Manage error case
        # 3. GET v2/{{tenant_id}}/os-floating-ips
        #    If any IP is available, use it
        #    Else fail
        def resolve_floating_ip(env)
          config = env[:machine].provider_config
          nova = env[:openstack_client].nova
          return config.floating_ip if config.floating_ip
          floating_ips = nova.get_all_floating_ips(env)
          if config.floating_ip_pool
            floating_ips.each do |single|
              return single.ip if single.pool == config.floating_ip_pool && single.instance_id.nil?
            end
            return nova.allocate_floating_ip(env, config.floating_ip_pool).ip
          else
            floating_ips.each do |ip|
              return ip.ip if ip.instance_id.nil?
            end
          end
          fail Errors::UnableToResolveFloatingIP
        end

        def resolve_flavor(env)
          @logger.info 'Resolving flavor'
          config = env[:machine].provider_config
          nova = env[:openstack_client].nova
          env[:ui].info(I18n.t('vagrant_openstack.finding_flavor'))
          flavors = nova.get_all_flavors(env)
          @logger.info "Finding flavor matching name '#{config.flavor}'"
          flavor = find_matching(flavors, config.flavor)
          fail Errors::NoMatchingFlavor unless flavor
          flavor
        end

        def resolve_image(env)
          @logger.info 'Resolving image'
          config = env[:machine].provider_config
          nova = env[:openstack_client].nova
          env[:ui].info(I18n.t('vagrant_openstack.finding_image'))
          images = nova.get_all_images(env)
          @logger.info "Finding image matching name '#{config.image}'"
          image = find_matching(images, config.image)
          fail Errors::NoMatchingImage unless image
          image
        end

        def resolve_networks(env)
          @logger.info 'Resolving network(s)'
          config = env[:machine].provider_config
          return [] if config.networks.nil? || config.networks.empty?
          env[:ui].info(I18n.t('vagrant_openstack.finding_networks'))

          private_networks = env[:openstack_client].neutron.get_private_networks(env)
          private_network_ids = private_networks.map { |n| n.id }

          networks = []
          config.networks.each do |network|
            if private_network_ids.include?(network)
              networks << network
              next
            end
            net_id = nil
            private_networks.each do |n| # Bad algorithm complexity, but here we don't care...
              next unless n.name.eql? network
              fail "Multiple networks with name '#{n.id}'" unless net_id.nil?
              net_id = n.id
            end
            fail "No matching network with name '#{network}'" if net_id.nil?
            networks << net_id
          end
          networks
        end

        def create_server(env, flavor, image, networks)
          config = env[:machine].provider_config
          nova = env[:openstack_client].nova
          server_name = config.server_name || env[:machine].name

          env[:ui].info(I18n.t('vagrant_openstack.launching_server'))
          env[:ui].info(" -- Tenant         : #{config.tenant_name}")
          env[:ui].info(" -- Name           : #{server_name}")
          env[:ui].info(" -- Flavor         : #{flavor.name}")
          env[:ui].info(" -- FlavorRef      : #{flavor.id}")
          env[:ui].info(" -- Image          : #{image.name}")
          env[:ui].info(" -- ImageRef       : #{image.id}")
          env[:ui].info(" -- KeyPair        : #{config.keypair_name}")
          unless networks.empty?
            if networks.size == 1
              env[:ui].info(" -- Network        : #{config.networks[0]}")
            else
              env[:ui].info(" -- Networks       : #{config.networks}")
            end
          end

          log = "Lauching server '#{server_name}' in project '#{config.tenant_name}' "
          log << "with flavor '#{flavor.name}' (#{flavor.id}), "
          log << "image '#{image.name}' (#{image.id}) "
          log << "and keypair '#{config.keypair_name}'"

          @logger.info(log)

          nova.create_server(env, server_name, image.id, flavor.id, networks, config.keypair_name)
        end

        def waiting_for_server_to_be_build(env, server_id)
          @logger.info 'Waiting for the server to be built...'
          env[:ui].info(I18n.t('vagrant_openstack.waiting_for_build'))
          nova = env[:openstack_client].nova
          timeout(200) do
            while nova.get_server_details(env, server_id)['status'] != 'ACTIVE'
              sleep 3
              @logger.debug('Waiting for server to be ACTIVE')
            end
          end
        end

        def port_open?(env, ip, port, timeout)
          start_time = Time.now
          current_time = start_time
          nb_retry = 0
          while (current_time - start_time) <= timeout
            begin
              @logger.debug "Checking if SSH port is open... Attempt number #{nb_retry}"
              if nb_retry % 5 == 0
                @logger.info 'Waiting for SSH to become available...'
                env[:ui].info(I18n.t('vagrant_openstack.waiting_for_ssh'))
              end
              TCPSocket.new(ip, port)
              return true
            rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ETIMEDOUT
              @logger.debug 'SSH port is not open... new retry in in 1 second'
              nb_retry += 1
              sleep 1
            end
            current_time = Time.now
          end
          false
        end

        # This method finds a matching _thing_ in a collection of
        # _things_. This works matching if the ID or NAME equals to
        # `name`. Or, if `name` is a regexp, a partial match is chosen
        # as well.
        def find_matching(collection, name)
          collection.each do |single|
            return single if single.id == name
            return single if single.name == name
            return single if name.is_a?(Regexp) && name =~ single.name
          end
          @logger.error "Flavor '#{name}' not found"
          nil
        end
      end
    end
  end
end
