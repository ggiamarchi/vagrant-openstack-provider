require 'log4r'
require 'socket'
require 'timeout'
require 'sshkey'

require 'vagrant-openstack-provider/config_resolver'
require 'vagrant-openstack-provider/utils'
require 'vagrant-openstack-provider/action/abstract_action'
require 'vagrant/util/retryable'

module VagrantPlugins
  module Openstack
    module Action
      class CreateServer < AbstractAction
        include Vagrant::Util::Retryable

        def initialize(app, _env, resolver = ConfigResolver.new, utils = Utils.new)
          @app = app
          @logger = Log4r::Logger.new('vagrant_openstack::action::create_server')
          @resolver = resolver
          @utils = utils
          @@mutex = Mutex.new
        end

        def execute(env)
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
            security_groups: @resolver.resolve_security_groups(env),
            user_data: env[:machine].provider_config.user_data,
            metadata: env[:machine].provider_config.metadata
          }

          server_id = create_server(env, options)

          # Store the ID right away so we can track it
          env[:machine].id = server_id

          env[:ui].info(" -- ID              : #{server_id}")

          waiting_for_server_to_be_built(env, server_id)
          @@mutex.synchronize do
            assign_floating_ip(env, server_id)
            waiting_for_floating_ip_to_be_assigned(env, server_id)
          end
          attach_volumes(env, server_id, options[:volumes]) unless options[:volumes].empty?

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
          env[:ui].info(" -- KeyPair         : #{options[:keypair_name]}") unless options[:keypair_name].nil?

          unless options[:networks].empty?
            formated_networks = ' -- '
            if options[:networks].size == 1
              formated_networks << 'Network         : '
            else
              formated_networks << 'Networks        : '
            end
            formated_networks << options[:networks].map do |n|
              if n.key? :fixed_ip
                "#{n[:uuid]} (#{n[:fixed_ip]})"
              else
                n[:uuid]
              end
            end.join(', ')
            env[:ui].info(formated_networks)
          end

          unless options[:volumes].empty?
            options[:volumes].each do |volume|
              device = volume[:device]
              device = :auto if device.nil?
              env[:ui].info(" -- Volume attached : #{volume[:id]} => #{device}")
            end
          end

          log = "Launching server '#{server_name}' in project '#{config.tenant_name}' "
          log << "with flavor '#{options[:flavor].name}' (#{options[:flavor].id}), "
          unless options[:image].nil?
            log << "image '#{options[:image].name}' (#{options[:image].id}) "
          end
          unless options[:keypair_name].nil?
            log << "and keypair '#{options[:keypair_name]}'"
          end

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

        def waiting_for_server_to_be_built(env, server_id, retry_interval = 3)
          @logger.info "Waiting for the server with id #{server_id} to be built..."
          env[:ui].info(I18n.t('vagrant_openstack.waiting_for_build'))
          config = env[:machine].provider_config
          Timeout.timeout(config.server_create_timeout, Errors::Timeout) do
            server_status = 'WAITING'
            until server_status == 'ACTIVE'
              @logger.debug('Waiting for server to be ACTIVE')
              server_status = env[:openstack_client].nova.get_server_details(env, server_id)['status']
              fail Errors::ServerStatusError, server: server_id if server_status == 'ERROR'
              sleep retry_interval
            end
          end
        end

        def assign_floating_ip(env, server_id)
          floating_ip = @resolver.resolve_floating_ip(env)
          return if !floating_ip || floating_ip.empty?
          @logger.info "Using floating IP #{floating_ip}"
          env[:ui].info(I18n.t('vagrant_openstack.using_floating_ip', floating_ip: floating_ip))
          env[:openstack_client].nova.add_floating_ip(env, server_id, floating_ip)
        rescue Errors::UnableToResolveFloatingIP
          @logger.info 'Vagrant was unable to resolve FloatingIP, continue assuming it is not necessary'
        end

        def waiting_for_floating_ip_to_be_assigned(env, server_id, retry_interval = 3)
          floating_ip = @resolver.resolve_floating_ip(env)
          return if !floating_ip || floating_ip.empty?
          @logger.info "Waiting for floating IP #{floating_ip} to be assigned"
          env[:ui].info(I18n.t('vagrant_openstack.waiting_for_floating_ip', floating_ip: floating_ip))
          config = env[:machine].provider_config
          Timeout.timeout(config.floating_ip_assign_timeout, Errors::Timeout) do
            until env[:openstack_client].nova.check_assigned_floating_ip(env, server_id, floating_ip)
              sleep retry_interval
            end
            return
          end
        rescue Errors::UnableToResolveFloatingIP
          @logger.info 'Vagrant was unable to resolve FloatingIP, not waiting for assignment'
        end

        def attach_volumes(env, server_id, volumes)
          @logger.info("Attaching volumes #{volumes} to server #{server_id}")
          volumes.each do |volume|
            @logger.debug("Attaching volumes #{volume}")
            env[:openstack_client].nova.attach_volume(env, server_id, volume[:id], volume[:device])
          end
        end
      end
    end
  end
end
