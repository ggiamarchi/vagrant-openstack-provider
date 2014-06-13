module VagrantPlugins
  module Openstack
    module Action
      class Suspend
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if env[:machine].id
            env[:ui].info I18n.t("vagrant.actions.vm.suspend.suspending")
            client = env[:openstack_client]
            client.suspend_server(env, env[:machine].id)
          end

          @app.call(env)
        end
      end
    end
  end
end
