require "log4r"

module VagrantPlugins
  module Openstack
    module Action
      # This action reads the SSH info for the machine and puts it into the
      # `:machine_ssh_info` key in the environment.
      class ReadSSHInfo
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_openstack::action::read_ssh_info")
        end

        def call(env)
          env[:machine_ssh_info] = read_ssh_info(env[:openstack_compute], env[:machine])

          @app.call(env)
        end

        def read_ssh_info(openstack, machine)
          return nil if machine.id.nil?

          # Find the machine
          server = openstack.servers.get(machine.id)
          if server.nil?
            # The machine can't be found
            @logger.info("Machine couldn't be found, assuming it got destroyed.")
            machine.id = nil
            return nil
          end

          config = machine.provider_config

          # Read the DNS info
          return {
            # Usually there should only be one public IP
            :host => server.addresses['public'].last['addr'],
            :port => 22,
            :username => config.ssh_username
          }
        end
      end
    end
  end
end
