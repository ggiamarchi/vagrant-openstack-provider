module VagrantPlugins
  module Openstack
    module Action
      class MessageAlreadySuspended
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info(I18n.t("vagrant_openstack.already_suspended"))
          @app.call(env)
        end
      end
    end
  end
end
