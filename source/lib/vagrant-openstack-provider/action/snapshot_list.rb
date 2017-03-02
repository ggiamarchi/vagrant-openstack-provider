require 'vagrant-openstack-provider/action/abstract_action'

module VagrantPlugins
  module Openstack
    module Action
      class SnapshotList < AbstractAction
        def initialize(app, _env)
          @app = app
        end

        def call(env)
          nova = env[:openstack_client].nova
          machine_snapshots = nova.list_snapshots(env, env[:machine].id)

          env[:machine_snapshot_list] = machine_snapshots.map(&:name)

          @app.call env
        end
      end
    end
  end
end
