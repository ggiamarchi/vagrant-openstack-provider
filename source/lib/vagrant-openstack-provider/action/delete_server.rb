require 'log4r'

require 'vagrant-openstack-provider/action/abstract_action'

module VagrantPlugins
  module Openstack
    module Action
      # This deletes the running server, if there is one.
      class DeleteServer < AbstractAction
        def initialize(app, _env)
          @app    = app
          @logger = Log4r::Logger.new('vagrant_openstack::action::delete_server')
        end

        def execute(env)
          if env[:machine].id
            @logger.info "Deleting server #{env[:machine].id}..."
            env[:ui].info(I18n.t('vagrant_openstack.deleting_server'))
            env[:openstack_client].nova.delete_server(env, env[:machine].id)
            env[:openstack_client].nova.delete_keypair_if_vagrant(env, env[:machine].id)

            waiting_for_instance_to_be_deleted(env, env[:machine].id)

          end

          @app.call(env)
        end

        private

        def waiting_for_instance_to_be_deleted(env, instance_id, retry_interval = 3, timeout = 200)
          @logger.info "Waiting for the instance with id #{instance_id} to be deleted..."
          env[:ui].info(I18n.t('vagrant_openstack.waiting_deleted'))
          timeout(timeout, Errors::Timeout) do
            delete_ok = false
            until delete_ok
              begin
                @logger.debug('Waiting for instance to be DELETED')
                server_status = env[:openstack_client].nova.get_server_details(env, instance_id)['status']
                fail Errors::ServerStatusError, server: instance_id if server_status == 'ERROR'
                break if server_status == 'DELETED'
                sleep retry_interval
              rescue Errors::InstanceNotFound
                delete_ok = true
              end
            end
          end
        end
      end
    end
  end
end
