module VagrantPlugins
  module Openstack
    module Action
      class Message
        def initialize(app, _env, message)
          @app = app
          @message = message
        end

        def call(env)
          env[:ui].info(@message)
          @app.call(env)
        end
      end
    end
  end
end
