require "log4r"

module VagrantPlugins
  module Rackspace
    module Action
      # This action reads the SSH info for the machine and puts it into the
      # `:machine_ssh_info` key in the environment.
      class ReadSSHInfo
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_rackspace::action::read_ssh_info")
        end

        def call(env)
          env[:machine_ssh_info] = read_ssh_info(env[:rackspace_compute], env[:machine])

          @app.call(env)
        end

        def read_ssh_info(rackspace, machine)
          return nil if machine.id.nil?

          # Find the machine
          server = rackspace.servers.get(machine.id)
          if server.nil?
            # The machine can't be found
            @logger.info("Machine couldn't be found, assuming it got destroyed.")
            machine.id = nil
            return nil
          end

          # Read the DNS info
          return {
            :host => server.ipv4_address,
            :port => 22,
            :username => "root"
          }
        end
      end
    end
  end
end
