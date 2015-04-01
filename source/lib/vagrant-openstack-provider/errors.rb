require 'vagrant'

module VagrantPlugins
  module Openstack
    module Errors
      class VagrantOpenstackError < Vagrant::Errors::VagrantError
        #
        # Added for vagrant 1.4.x compatibility This attribute had been
        # added in Vagrant::Errors::VagrantError form the version 1.5.0
        #
        attr_accessor :extra_data

        def initialize(args = nil)
          @extra_data = args
          super(args)
        end

        error_namespace('vagrant_openstack.errors')
        error_key(:default)
      end

      class Timeout < VagrantOpenstackError
        error_key(:timeout)
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

      class NoMatchingApiVersion < VagrantOpenstackError
        error_key(:no_matching_api_version)
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

      class ConflictBootVolume < VagrantOpenstackError
        error_key(:conflict_boot_volume)
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

      class UnrecognizedArgForCommand < VagrantOpenstackError
        error_key(:unrecognized_arg_for_command)
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

      class InvalidNetworkObject < VagrantOpenstackError
        error_key(:invalid_network_format)
      end

      class UnresolvedNetwork < VagrantOpenstackError
        error_key(:unresolved_network)
      end

      class UnresolvedNetworkId < VagrantOpenstackError
        error_key(:unresolved_network_id)
      end

      class UnresolvedNetworkName < VagrantOpenstackError
        error_key(:unresolved_network_name)
      end

      class ConflictNetworkNameId < VagrantOpenstackError
        error_key(:conflict_network_name_id)
      end

      class MultipleNetworkName < VagrantOpenstackError
        error_key(:multiple_network_name)
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

      class InstanceNotFound < VagrantOpenstackError
        error_key(:instance_not_found)
      end

      class StackNotFound < VagrantOpenstackError
        error_key(:stack_not_found)
      end

      class NetworkServiceUnavailable < VagrantOpenstackError
        error_key(:nerwork_service_unavailable)
      end

      class VolumeServiceUnavailable < VagrantOpenstackError
        error_key(:volume_service_unavailable)
      end

      class FloatingIPAlreadyAssigned < VagrantOpenstackError
        error_key(:floating_ip_already_assigned)
      end

      class FloatingIPNotAvailable < VagrantOpenstackError
        error_key(:floating_ip_not_available)
      end

      class ServerStatusError < VagrantOpenstackError
        error_key(:server_status_error)
      end

      class StackStatusError < VagrantOpenstackError
        error_key(:stack_status_error)
      end

      class MissingNovaEndpoint < VagrantOpenstackError
        error_key(:missing_nova_endpoint)
      end
    end
  end
end
