require 'log4r'

module VagrantPlugins
  module Openstack
    module Action
      # This action reads the SSH info for the machine and puts it into the
      # `:machine_ssh_info` key in the environment.
      class ReadSSHInfo
        def initialize(app, _env)
          @app    = app
          @logger = Log4r::Logger.new('vagrant_openstack::action::read_ssh_info')
        end

        def call(env)
          @logger.info 'Reading SSH info'
          env[:machine_ssh_info] = read_ssh_info(env)

          @app.call(env)
        end

        private

        def read_ssh_info(env)
          config = env[:machine].provider_config
          {
            host: get_ip_address(env),
            port: 22,
            username: config.ssh_username
          }
        end

        def get_ip_address(env)
          return env[:machine].provider_config.floating_ip unless env[:machine].provider_config.floating_ip.nil?
          details = env[:openstack_client].nova.get_server_details(env, env[:machine].id)
          details['addresses'].each do |network|
            network[1].each do |network_detail|
              return network_detail['addr'] if network_detail['OS-EXT-IPS:type'] == 'floating'
            end
          end
          fail Errors::UnableToResolveIP
        end
      end
    end
  end
end
