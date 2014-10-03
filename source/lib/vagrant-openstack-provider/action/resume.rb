require 'vagrant-openstack-provider/action/abstract_action'

module VagrantPlugins
  module Openstack
    module Action
      class Resume < AbstractAction
        def initialize(app, _env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_openstack::action::resume_server')
        end

        def execute(env)
          if env[:machine].id
            @logger.info "Resuming suspended VM #{env[:machine].id}..."
            env[:ui].info I18n.t('vagrant.actions.vm.resume.resuming')
            env[:openstack_client].nova.resume_server(env, env[:machine].id)
          end

          @app.call(env)
        end
      end
    end
  end
end
