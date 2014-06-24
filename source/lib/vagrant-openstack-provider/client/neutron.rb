require 'log4r'
require 'restclient'
require 'json'

require 'vagrant-openstack-provider/client/utils'

module VagrantPlugins
  module Openstack
    class NeutronClient
      include Singleton
      include VagrantPlugins::Openstack::Utils

      def initialize
        @logger = Log4r::Logger.new('vagrant_openstack::neutron')
        @session = VagrantPlugins::Openstack.session
      end

      def get_private_networks(env)
        authenticated(env) do
          networks_json = RestClient.get("#{@session.endpoints[:network]}/networks",
                                         'X-Auth-Token' => @session.token,
                                         :accept => :json) { |res| handle_response(res) }
          networks = []
          JSON.parse(networks_json)['networks'].each do |n|
            networks << { id: n['id'], name: n['name'] } if n['tenant_id'].eql? @session.project_id
          end
          networks
        end
      end
    end
  end
end
