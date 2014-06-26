begin
  require 'vagrant'
rescue LoadError
  raise 'The Openstack Cloud provider must be run within Vagrant.'
end

# This is a sanity check to make sure no one is attempting to install
# this into an early Vagrant version.
if Vagrant::VERSION < '1.1.0'
  fail 'Openstack Cloud provider is only compatible with Vagrant 1.1+'
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

      provider(:openstack) do
        # Setup some things
        Openstack.init_i18n
        Openstack.init_logging

        # Load the actual provider
        require_relative 'provider'
        Provider
      end

      command('openstack') do
        require_relative 'command/main'
        Command::Main
      end
    end
  end
end
