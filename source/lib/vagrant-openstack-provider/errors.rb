require 'vagrant'

module VagrantPlugins
  module Openstack
    module Errors
      class VagrantOpenstackError < Vagrant::Errors::VagrantError
        error_namespace('vagrant_openstack.errors')
        error_key(:default)
      end

      class AuthenticationRequired < VagrantOpenstackError
        error_key(:authentication_required)
      end

      class AuthenticationFailed < VagrantOpenstackError
        error_key(:authentication_failed)
      end

      class BadAuthenticationEndpoint < VagrantOpenstackError
        error_key(:bad_authentication_endpoint)
      end

      class MultipleApiVersion < VagrantOpenstackError
        error_key(:multiple_api_version)
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

      class SyncMethodError < VagrantOpenstackError
        error_key(:sync_method_error)
      end

      class RsyncError < VagrantOpenstackError
        error_key(:rsync_error)
      end

      class SshUnavailable < VagrantOpenstackError
        error_key(:ssh_unavailble)
      end

      class NoArgRequiredForCommand < VagrantOpenstackError
        error_key(:no_arg_required_for_command)
      end

      class UnableToResolveFloatingIP < VagrantOpenstackError
        error_key(:unable_to_resolve_floating_ip)
      end

      class UnableToResolveIP < VagrantOpenstackError
        error_key(:unable_to_resolve_ip)
      end

      class UnableToResolveSSHKey < VagrantOpenstackError
        error_key(:unable_to_resolve_ssh_key)
      end

      class InvalidVolumeObject < VagrantOpenstackError
        error_key(:invalid_volume_format)
      end

      class UnresolvedVolume < VagrantOpenstackError
        error_key(:unresolved_volume)
      end

      class UnresolvedVolumeId < VagrantOpenstackError
        error_key(:unresolved_volume_id)
      end

      class UnresolvedVolumeName < VagrantOpenstackError
        error_key(:unresolved_volume_name)
      end

      class ConflictVolumeNameId < VagrantOpenstackError
        error_key(:conflict_volume_name_id)
      end

      class MultipleVolumeName < VagrantOpenstackError
        error_key(:multiple_volume_name)
      end

      class MissingBootOption < VagrantOpenstackError
        error_key(:missing_boot_option)
      end

      class ConflictBootOption < VagrantOpenstackError
        error_key(:conflict_boot_option)
      end

      class NoMatchingSshUsername < VagrantOpenstackError
        error_key(:ssh_username_missing)
      end
    end
  end
end
