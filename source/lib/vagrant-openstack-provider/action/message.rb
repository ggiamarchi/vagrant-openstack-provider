require 'vagrant-openstack-provider/action/abstract_action'

module VagrantPlugins
  module Openstack
    module Action
      class Message < AbstractAction
        def initialize(app, _env, message)
          @app = app
          @message = message
        end

        def execute(env)
          env[:ui].info(@message)
          @app.call(env)
        end
      end
    end
  end
end
