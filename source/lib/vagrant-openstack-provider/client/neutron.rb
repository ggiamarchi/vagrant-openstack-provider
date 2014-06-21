require 'log4r'
require 'restclient'
require 'json'

module VagrantPlugins
  module Openstack
    class NeutronClient
      def initialize
        @logger = Log4r::Logger.new('vagrant_openstack::neutron')
        @session = VagrantPlugins::Openstack.session
      end

      def get_private_networks(_env)
        networks_json = RestClient.get("#{@session.endpoints[:network]}/networks", 'X-Auth-Token' => @session.token, :accept => :json)
        networks = []
        JSON.parse(networks_json)['networks'].each do |n|
          networks << { id: n['id'], name: n['name'] } if n['tenant_id'].eql? @session.project_id
        end
        networks
      end
    end
  end
end
