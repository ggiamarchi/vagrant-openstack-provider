begin
  require 'vagrant'
rescue LoadError
  raise 'The Openstack Cloud provider must be run within Vagrant.'
end

require 'vagrant-openstack-provider/version_checker'

# This is a sanity check to make sure no one is attempting to install
# this into an early Vagrant version.
if Vagrant::VERSION < '1.4.0'
  fail 'Openstack Cloud provider is only compatible with Vagrant 1.4+'
end

module VagrantPlugins
  module Openstack
    class Plugin < Vagrant.plugin('2')
      name 'Openstack Cloud'
      description <<-DESC
      This plugin enables Vagrant to manage machines in Openstack Cloud.
      DESC

      config(:openstack, :provider) do
        require_relative 'config'
        Config
      end

      provider(:openstack, box_optional: true) do
        Openstack.init_i18n
        Openstack.init_logging
        VagrantPlugins::Openstack.check_version

        # Load the actual provider
        require_relative 'provider'
        Provider
      end

      # add a capability to get proper winrm_info (password) from openstack
      provider_capability(:openstack, :winrm_info) do
        require_relative 'cap'
        Cap
      end

      command('openstack') do
        Openstack.init_i18n
        Openstack.init_logging
        VagrantPlugins::Openstack.check_version

        require_relative 'command/main'
        Command::Main
      end
    end
  end
end
