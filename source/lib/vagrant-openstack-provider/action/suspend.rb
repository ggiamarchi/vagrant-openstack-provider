require 'vagrant-openstack-provider/action/abstract_action'

module VagrantPlugins
  module Openstack
    module Action
      class Suspend < AbstractAction
        def initialize(app, _env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_openstack::action::suspend_server')
        end

        def execute(env)
          if env[:machine].id
            @logger.info "Saving VM #{env[:machine].id} state and suspending execution..."
            env[:ui].info I18n.t('vagrant.actions.vm.suspend.suspending')
            env[:openstack_client].nova.suspend_server(env, env[:machine].id)
          end

          @app.call(env)
        end
      end
    end
  end
end
