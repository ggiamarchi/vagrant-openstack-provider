require 'vagrant-openstack-provider/action/abstract_action'

module VagrantPlugins
  module Openstack
    module Action
      class SnapshotSave < AbstractAction
        def initialize(app, _env, retry_interval = 3)
          @app = app
          @retry_interval = retry_interval
        end

        def call(env)
          nova = env[:openstack_client].nova
          config = env[:machine].provider_config

          env[:ui].info(I18n.t('vagrant.actions.vm.snapshot.saving',
                               name: env[:snapshot_name]))

          nova.create_snapshot(
            env,
            env[:machine].id, env[:snapshot_name])

          image = nova.list_snapshots(env, env[:machine].id).find { |i| i.name == env[:snapshot_name] }

          timeout(config.server_create_timeout, Errors::Timeout) do
            loop do
              image_status = nova.get_image_details(env, image.id)

              break if image_status['status'] == 'ACTIVE'

              unless image_status['progress'].nil?
                env[:ui].clear_line
                env[:ui].report_progress(image_status['progress'], 100, false)
              end

              sleep @retry_interval
            end
          end

          # Clear progress output.
          env[:ui].clear_line

          env[:ui].success(I18n.t('vagrant.actions.vm.snapshot.saved',
                                  name: env[:snapshot_name]))

          @app.call env
        end
      end
    end
  end
end
