require "log4r"

module VagrantPlugins
  module Openstack
    module Action
      # This action reads the SSH info for the machine and puts it into the
      # `:machine_ssh_info` key in the environment.
      class ReadSSHInfo
        def initialize(app, _env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_openstack::action::read_ssh_info")
        end

        def call(env)
          env[:machine_ssh_info] = read_ssh_info(env)

          @app.call(env)
        end

        def read_ssh_info(env)
          config = env[:machine].provider_config
          {
            # Usually there should only be one public IP
            host: config.floating_ip,
            port: 22,
            username: config.ssh_username
          }
        end
      end
    end
  end
end
