module VagrantPlugins
  module Openstack
    module Action
      class Resume
        def initialize(app, _env)
          @app = app
        end

        def call(env)
          if env[:machine].id
            env[:ui].info I18n.t("vagrant.actions.vm.resume.resuming")
            client = env[:openstack_client]
            client.resume_server(env, env[:machine].id)
          end

          @app.call(env)
        end
      end
    end
  end
end
