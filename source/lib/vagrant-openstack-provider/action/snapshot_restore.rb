require 'vagrant-openstack-provider/action/abstract_action'

module VagrantPlugins
  module Openstack
    module Action
      class SnapshotRestore < AbstractAction
        def initialize(app, _env)
          @app = app
        end

        def call(env)
          nova = env[:openstack_client].nova
          machine_snapshots = nova.list_snapshots(env, env[:machine].id)

          snapshot = machine_snapshots.find { |s| s.name == env[:snapshot_name] }

          unless snapshot.nil?
            env[:ui].info(I18n.t('vagrant.actions.vm.snapshot.restoring',
                                 name: snapshot.name))

            nova.restore_snapshot(env, env[:machine].id, snapshot.id)
          end

          @app.call env
        end
      end
    end
  end
end
