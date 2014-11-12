require 'log4r'
require 'restclient'
require 'json'

require 'vagrant-openstack-provider/client/heat'
require 'vagrant-openstack-provider/client/keystone'
require 'vagrant-openstack-provider/client/nova'
require 'vagrant-openstack-provider/client/neutron'
require 'vagrant-openstack-provider/client/cinder'
require 'vagrant-openstack-provider/client/glance'

module VagrantPlugins
  module Openstack
    class Session
      include Singleton

      attr_accessor :token
      attr_accessor :project_id
      attr_accessor :endpoints

      def initialize
        @token = nil
        @project_id = nil
        @endpoints = {}
      end

      def reset
        initialize
      end
    end

    def self.session
      Session.instance
    end

    def self.keystone
      Openstack::KeystoneClient.instance
    end

    def self.nova
      Openstack::NovaClient.instance
    end

    def self.heat
      Openstack::HeatClient.instance
    end

    def self.neutron
      Openstack::NeutronClient.instance
    end

    def self.cinder
      Openstack::CinderClient.instance
    end

    def self.glance
      Openstack::GlanceClient.instance
    end
  end
end
