require "log4r"

module VagrantPlugins
  module Openstack
    module Action
      class StartServer
        def initialize(app, _env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_openstack::action::start_server")
        end

        def call(env)
          if env[:machine].id
            env[:ui].info(I18n.t("vagrant_openstack.starting_server"))
            env[:openstack_client].nova.start_server(env, env[:machine].id)
          end
          @app.call(env)
        end
      end
    end
  end
end
