require 'log4r'

module VagrantPlugins
  module Openstack
    module Action
      # This action reads the state of the machine and puts it in the
      # `:machine_state_id` key in the environment.
      class ReadState
        def initialize(app, _env)
          @app    = app
          @logger = Log4r::Logger.new('vagrant_openstack::action::read_state')
        end

        def call(env)
          env[:machine_state_id] = read_state(env)       
          @app.call(env)
        end

        def read_state(env)
          machine = env[:machine]
          return :not_created if machine.id.nil?

          # Find the machine
          server = env[:openstack_client].nova.get_server_details(env, machine.id)
          if server.nil? || server['status'] == 'DELETED'
            # The machine can't be found
            @logger.info('Machine not found or deleted, assuming it got destroyed.')
            machine.id = nil
            return :not_created
          end

          server['status'].downcase.to_sym
        end    
      end

      class ReadTask
        def initialize(app, _env)
          @app    = app
          @logger = Log4r::Logger.new('vagrant_openstack::action::read_task')
        end

        def call(env)
          env[:machine_task_id] = read_task(env)   
          @app.call(env)
        end

        def read_task(env)
          machine = env[:machine]
          return :not_created if machine.id.nil?

          # Find the machine
          server = env[:openstack_client].nova.get_server_details(env, machine.id)
          if server.nil? || server['status'] == 'DELETED'
            # The machine can't be found
            @logger.info('Machine not found or deleted, assuming it got destroyed.')
            machine.id = nil
            return :not_created
          end

          # Return the state
          if !server['OS-EXT-STS:task_state'].nil? 
            server['OS-EXT-STS:task_state'].downcase.to_sym
          end  
        end
      end
    end
  end
end
