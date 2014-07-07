require 'log4r'
require 'restclient'
require 'json'

require 'vagrant-openstack-provider/client/http_utils'

module VagrantPlugins
  module Openstack
    class NeutronClient
      include Singleton
      include VagrantPlugins::Openstack::HttpUtils

      def initialize
        @logger = Log4r::Logger.new('vagrant_openstack::neutron')
        @session = VagrantPlugins::Openstack.session
      end

      def get_api_version_list(_env)
        json = RestClient.get(@session.endpoints[:network], 'X-Auth-Token' => @session.token, :accept => :json) do |response|
          log_response(response)
          case response.code
          when 200, 300
            response
          when 401
            fail Errors::AuthenticationFailed
          else
            fail Errors::VagrantOpenstackError, message: response.to_s
          end
        end
        JSON.parse(json)['versions']
      end

      def get_private_networks(env)
        networks_json = get(env, "#{@session.endpoints[:network]}/networks")
        networks = []
        JSON.parse(networks_json)['networks'].each do |n|
          networks << Item.new(n['id'], n['name']) if n['tenant_id'].eql? @session.project_id
        end
        networks
      end
    end
  end
end
