require 'log4r'

require 'vagrant-openstack-provider/config_resolver'
require 'vagrant-openstack-provider/utils'
require 'vagrant-openstack-provider/action/abstract_action'

module VagrantPlugins
  module Openstack
    module Action
      # This action reads the SSH info for the machine and puts it into the
      # `:machine_ssh_info` key in the environment.

      class ReadSSHInfo < AbstractAction
        def initialize(app, _env, resolver = ConfigResolver.new, utils = Utils.new)
          @app    = app
          @logger = Log4r::Logger.new('vagrant_openstack::action::read_ssh_info')
          @resolver = resolver
          @utils = utils
        end

        def execute(env)
          @logger.info 'Reading SSH info'
          server_id = env[:machine].id.to_sym
          SSHInfoHolder.instance.tap do |holder|
            holder.synchronize do
              holder.ssh_info[server_id] = read_ssh_info(env) if holder.ssh_info[server_id].nil?
              env[:machine_ssh_info] = holder.ssh_info[server_id]
            end
          end
          @app.call(env)
        end

        private

        def read_ssh_info(env)
          config = env[:machine].provider_config
          env[:ui].warn('SSH is disabled in the provider config. The action you are attempting is likely to fail') if config.ssh_disabled
          hash = {
            host: @utils.get_ip_address(env),
            port: @resolver.resolve_ssh_port(env),
            username: @resolver.resolve_ssh_username(env)
          }
          hash[:private_key_path] = "#{env[:machine].data_dir}/#{get_keypair_name(env)}" unless config.keypair_name || config.public_key_path
          # Should work silently when https://github.com/mitchellh/vagrant/issues/4637 is fixed
          hash[:log_level] = 'ERROR'
          hash
        end

        def get_keypair_name(env)
          env[:openstack_client].nova.get_server_details(env, env[:machine].id)['key_name']
        end
      end

      class SSHInfoHolder < Mutex
        include Singleton

        #
        # Keys are machine ids
        #
        attr_accessor :ssh_info

        def initialize
          @ssh_info = {}
        end
      end

      def self.get_ssh_info(env)
        SSHInfoHolder.instance.ssh_info[env[:machine].id.to_sym]
      end
    end
  end
end
