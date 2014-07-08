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

      class MultipleApiUrl < VagrantOpenstackError
        error_key(:multiple_api_url)
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
    end
  end
end
