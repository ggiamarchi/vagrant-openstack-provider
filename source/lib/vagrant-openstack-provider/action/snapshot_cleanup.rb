require 'vagrant-openstack-provider/action/abstract_action'

module VagrantPlugins
  module Openstack
    module Action
      class SnapshotCleanup < AbstractAction
        def initialize(app, _env)
          @app = app
        end

        def call(env)
          nova = env[:openstack_client].nova
          machine_snapshots = nova.list_snapshots(env, env[:machine].id)

          snapshots_to_clean = machine_snapshots.select do |s|
            s.metadata.key?('vagrant_snapshot')
          end

          @app.call env

          unless snapshots_to_clean.empty?
            env[:ui].info("Deleting Vagrant snapshots: #{snapshots_to_clean.map(&:name)}")
          end

          snapshots_to_clean.each do |s|
            nova.delete_snapshot(env, s.id)
          end
        end
      end
    end
  end
end
