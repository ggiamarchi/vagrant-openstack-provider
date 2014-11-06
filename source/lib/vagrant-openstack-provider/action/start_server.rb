require 'log4r'

require 'vagrant-openstack-provider/action/abstract_action'

module VagrantPlugins
  module Openstack
    module Action
      class StartServer < AbstractAction
        def initialize(app, _env)
          @app    = app
          @logger = Log4r::Logger.new('vagrant_openstack::action::start_server')
        end

        def execute(env)
          if env[:machine].id
            env[:ui].info(I18n.t('vagrant_openstack.starting_server'))
            env[:openstack_client].nova.start_server(env, env[:machine].id)
          end
          @app.call(env)
        end
      end
    end
  end
end
