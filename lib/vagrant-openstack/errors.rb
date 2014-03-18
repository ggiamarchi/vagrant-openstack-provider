require "vagrant"

module VagrantPlugins
  module Openstack
    module Errors
      class VagrantOpenstackError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_openstack.errors")
      end

      class CreateBadState < VagrantOpenstackError
        error_key(:create_bad_state)
      end

      class NoMatchingFlavor < VagrantOpenstackError
        error_key(:no_matching_flavor)
      end

      class NoMatchingImage < VagrantOpenstackError
        error_key(:no_matching_image)
      end

      class RsyncError < VagrantOpenstackError
        error_key(:rsync_error)
      end

      class SshUnavailable < VagrantOpenstackError
        error_key(:ssh_unavailble)
      end

    end
  end
end
