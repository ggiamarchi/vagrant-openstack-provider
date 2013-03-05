require "vagrant"

module VagrantPlugins
  module Rackspace
    module Errors
      class VagrantRackspaceError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_rackspace.errors")
      end

      class CreateBadState < VagrantRackspaceError
        error_key(:create_bad_state)
      end

      class NoMatchingFlavor < VagrantRackspaceError
        error_key(:no_matching_flavor)
      end

      class NoMatchingImage < VagrantRackspaceError
        error_key(:no_matching_image)
      end

      class RsyncError < VagrantRackspaceError
        error_key(:rsync_error)
      end
    end
  end
end
