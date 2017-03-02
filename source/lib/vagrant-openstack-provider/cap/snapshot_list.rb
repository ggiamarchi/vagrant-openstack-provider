module VagrantPlugins
  module Openstack
    module Cap
      module SnapshotList
        # Returns a list of the snapshots that are taken on this machine.
        #
        # @return [Array<String>]
        def self.snapshot_list(machine)
          env = machine.action(:snapshot_list, lock: false)
          env[:machine_snapshot_list]
        end
      end
    end
  end
end
