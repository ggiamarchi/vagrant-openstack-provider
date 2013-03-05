begin
  require "vagrant"
rescue LoadError
  raise "The RackSpace Cloud provider must be run within Vagrant."
end

# This is a sanity check to make sure no one is attempting to install
# this into an early Vagrant version.
if Vagrant::VERSION < "1.1.0"
  raise "RackSpace Cloud provider is only compatible with Vagrant 1.1+"
end

module VagrantPlugins
  module Rackspace
    class Plugin < Vagrant.plugin("2")
      name "RackSpace Cloud"
      description <<-DESC
      This plugin enables Vagrant to manage machines in RackSpace Cloud.
      DESC

      config(:rackspace, :provider) do
        require_relative "config"
        Config
      end

      provider(:rackspace) do
        # Setup some things
        Rackspace.init_i18n
        Rackspace.init_logging

        # Load the actual provider
        require_relative "provider"
        Provider
      end
    end
  end
end
