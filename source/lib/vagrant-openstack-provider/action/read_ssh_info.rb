require 'log4r'

require 'vagrant-openstack-provider/config_resolver'
require 'vagrant-openstack-provider/utils'

module VagrantPlugins
  module Openstack
    module Action
      # This action reads the SSH info for the machine and puts it into the
      # `:machine_ssh_info` key in the environment.
      class ReadSSHInfo
        def initialize(app, _env, resolver = nil, utils = nil)
          @app    = app
          @logger = Log4r::Logger.new('vagrant_openstack::action::read_ssh_info')
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
          @logger.info 'Reading SSH info'
          env[:machine_ssh_info] = read_ssh_info(env)

          @app.call(env)
        end

        private

        def read_ssh_info(env)
          config = env[:machine].provider_config
          hash = {
            host: @utils.get_ip_address(env),
            port: @resolver.resolve_ssh_port(env),
            username: @resolver.resolve_ssh_username(env)
          }
          hash[:private_key_path] = "#{env[:machine].data_dir}/#{get_keypair_name(env)}" unless config.keypair_name || config.public_key_path
          hash
        end

        def get_keypair_name(env)
          env[:openstack_client].nova.get_server_details(env, env[:machine].id)['key_name']
        end
      end
    end
  end
end
