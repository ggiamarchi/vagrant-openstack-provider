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

      provider(:openstack, box_optional: true, parallel: true) do
        Openstack.init_i18n
        Openstack.init_logging

        # Load the actual provider
        require_relative 'provider'
        Provider
      end

      # TODO: Remove the if guard when Vagrant 1.8.0 is the minimum version.
      # rubocop:disable IndentationWidth
      if Gem::Version.new(Vagrant::VERSION) >= Gem::Version.new('1.8.0')
      provider_capability('openstack', 'snapshot_list') do
        require_relative 'cap/snapshot_list'
        Cap::SnapshotList
      end
      end
      # rubocop:enable IndentationWidth

      command('openstack') do
        Openstack.init_i18n
        Openstack.init_logging

        require_relative 'command/main'
        Command::Main
      end
    end
  end
end
