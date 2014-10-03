require 'log4r'
require 'socket'
require 'timeout'
require 'sshkey'

require 'vagrant-openstack-provider/config_resolver'
require 'vagrant-openstack-provider/utils'
require 'vagrant/util/retryable'

module VagrantPlugins
  module Openstack
    module Action
      class CreateServer
        include Vagrant::Util::Retryable

        def initialize(app, _env, resolver = nil, utils = nil)
          @app = app
          @logger = Log4r::Logger.new('vagrant_openstack::action::create_server')
          if resolver.nil?
            @resolver = VagrantPlugins::Openstack::ConfigResolver.new
          else
            @resolver = resolver
          end
          if utils.nil?
            @utils = VagrantPlugins::Openstack::Utils.new
          else
            @utils = utils
          end
        end

        def call(env)
          @logger.info 'Start create server action'

          config = env[:machine].provider_config

          fail Errors::MissingBootOption if config.image.nil? && config.volume_boot.nil?
          fail Errors::ConflictBootOption unless config.image.nil? || config.volume_boot.nil?

          options = {
            flavor: @resolver.resolve_flavor(env),
            image: @resolver.resolve_image(env),
            volume_boot: @resolver.resolve_volume_boot(env),
            networks: @resolver.resolve_networks(env),
            volumes: @resolver.resolve_volumes(env),
            keypair_name: @resolver.resolve_keypair(env),
            availability_zone: env[:machine].provider_config.availability_zone,
            scheduler_hints: env[:machine].provider_config.scheduler_hints,
            security_groups: env[:machine].provider_config.security_groups,
            user_data: env[:machine].provider_config.user_data,
            metadata: env[:machine].provider_config.metadata
          }

          server_id = create_server(env, options)

          # Store the ID right away so we can track it
          env[:machine].id = server_id

          waiting_for_server_to_be_build(env, server_id)
          assign_floating_ip(env, server_id)
          attach_volumes(env, server_id, options[:volumes]) unless options[:volumes].empty?
          waiting_for_server_to_be_reachable(env)

          @app.call(env)
        end

        private

        def create_server(env, options)
          config = env[:machine].provider_config
          nova = env[:openstack_client].nova
          server_name = config.server_name || env[:machine].name

          env[:ui].info(I18n.t('vagrant_openstack.launching_server'))
          env[:ui].info(" -- Tenant          : #{config.tenant_name}")
          env[:ui].info(" -- Name            : #{server_name}")
          env[:ui].info(" -- Flavor          : #{options[:flavor].name}")
          env[:ui].info(" -- FlavorRef       : #{options[:flavor].id}")
          unless options[:image].nil?
            env[:ui].info(" -- Image           : #{options[:image].name}")
            env[:ui].info(" -- ImageRef        : #{options[:image].id}")
          end
          env[:ui].info(" -- Boot volume     : #{options[:volume_boot][:id]} (#{options[:volume_boot][:device]})") unless options[:volume_boot].nil?
          env[:ui].info(" -- KeyPair         : #{options[:keypair_name]}")

          unless options[:networks].empty?
            if options[:networks].size == 1
              env[:ui].info(" -- Network         : #{options[:networks][0]}")
            else
              env[:ui].info(" -- Networks        : #{options[:networks]}")
            end
          end

          unless options[:volumes].empty?
            options[:volumes].each do |volume|
              device = volume[:device]
              device = :auto if device.nil?
              env[:ui].info(" -- Volume attached : #{volume[:id]} => #{device}")
            end
          end

          log = "Lauching server '#{server_name}' in project '#{config.tenant_name}' "
          log << "with flavor '#{options[:flavor].name}' (#{options[:flavor].id}), "
          unless options[:image].nil?
            log << "image '#{options[:image].name}' (#{options[:image].id}) "
          end
          log << "and keypair '#{options[:keypair_name]}'"

          @logger.info(log)

          image_ref = options[:image].id unless options[:image].nil?

          create_opts = {
            name: server_name,
            image_ref: image_ref,
            volume_boot: options[:volume_boot],
            flavor_ref: options[:flavor].id,
            keypair: options[:keypair_name],
            availability_zone: options[:availability_zone],
            networks: options[:networks],
            scheduler_hints: options[:scheduler_hints],
            security_groups: options[:security_groups],
            user_data: options[:user_data],
            metadata: options[:metadata]
          }

          nova.create_server(env, create_opts)
        end

        def waiting_for_server_to_be_build(env, server_id)
          @logger.info 'Waiting for the server to be built...'
          env[:ui].info(I18n.t('vagrant_openstack.waiting_for_build'))
          timeout(200) do
            while env[:openstack_client].nova.get_server_details(env, server_id)['status'] != 'ACTIVE'
              sleep 3
              @logger.debug('Waiting for server to be ACTIVE')
            end
          end
        end

        def assign_floating_ip(env, server_id)
          floating_ip = @resolver.resolve_floating_ip(env)
          return if !floating_ip || floating_ip.empty?
          @logger.info "Using floating IP #{floating_ip}"
          env[:ui].info(I18n.t('vagrant_openstack.using_floating_ip', floating_ip: floating_ip))
          env[:openstack_client].nova.add_floating_ip(env, server_id, floating_ip)
        end

        def attach_volumes(env, server_id, volumes)
          @logger.info("Attaching volumes #{volumes} to server #{server_id}")
          volumes.each do |volume|
            @logger.debug("Attaching volumes #{volume}")
            env[:openstack_client].nova.attach_volume(env, server_id, volume[:id], volume[:device])
          end
        end

        def waiting_for_server_to_be_reachable(env)
          ip = @utils.get_ip_address(env)
          return if env[:interrupted]

          env[:ui].clear_line

          ssh_timeout = env[:machine].provider_config.ssh_timeout
          unless port_open?(env, ip, @resolver.resolve_ssh_port(env), ssh_timeout)
            env[:ui].error(I18n.t('vagrant_openstack.timeout'))
            fail Errors::SshUnavailable, host: ip, timeout: ssh_timeout
          end

          @logger.info 'The server is ready'
          env[:ui].info(I18n.t('vagrant_openstack.ready'))
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
          @logger.error "Element '#{name}' not found in collection #{collection}"
          nil
        end
      end
    end
  end
end
