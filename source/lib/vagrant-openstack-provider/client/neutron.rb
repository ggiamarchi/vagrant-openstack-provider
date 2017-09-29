require 'log4r'
require 'json'

require 'vagrant-openstack-provider/client/http_utils'
require 'vagrant-openstack-provider/client/domain'

module VagrantPlugins
  module Openstack
    class NeutronClient
      include Singleton
      include VagrantPlugins::Openstack::HttpUtils
      include VagrantPlugins::Openstack::Domain

      def initialize
        @logger = Log4r::Logger.new('vagrant_openstack::neutron')
        @session = VagrantPlugins::Openstack.session
      end

      def get_private_networks(env)
        get_networks(env, false)
      end

      def get_all_networks(env)
        get_networks(env, true)
      end

      def get_subnets(env)
        network_response = get(env, "#{@session.endpoints[:network]}")
        network_resources = JSON.parse(network_response)['resources']
        subnets_resource = network_resources.find { |x| x['name'] == 'subnet' }
        subnets_url = subnets_resource['links'].find { |x| x['rel'] == 'self' }['href']
        subnets_json = get(env, subnets_url)
        subnets = []
        JSON.parse(subnets_json)['subnets'].each do |n|
          subnets << Subnet.new(n['id'], n['name'], n['cidr'], n['enable_dhcp'], n['network_id'])
        end
        subnets
      end

      private

      def get_networks(env, all)
        network_response = get(env, "#{@session.endpoints[:network]}")
        network_resources = JSON.parse(network_response)['resources']
        networks_resource = network_resources.find { |x| x['name'] == 'network' }
        networks_url = networks_resource['links'].find { |x| x['rel'] == 'self' }['href']
        networks_json = get(env, networks_url)
        networks = []
        JSON.parse(networks_json)['networks'].each do |n|
          networks << Item.new(n['id'], n['name']) if all || n['tenant_id'].eql?(@session.project_id)
        end
        networks
      end
    end
  end
end
