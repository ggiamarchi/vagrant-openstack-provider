require "log4r"
require "restclient"
require "json"

module VagrantPlugins
  module Openstack
    class OpenstackClient

      def initialize()
        @logger = Log4r::Logger.new("vagrant_openstack::openstack_client")
        @token = nil
      end

      def authenticate(env)
        @logger.debug("Authenticating on Keystone")
        config = env[:machine].provider_config
        authentication = RestClient.post(config.openstack_auth_url, {
          :auth => {
              :tenantName => config.tenant_name,
              :passwordCredentials => {
                :username => config.username,
                :password => config.api_key
              }
            }
          }.to_json,
          :content_type => :json,
          :accept => :json)

        @token = JSON.parse(authentication)['access']['token']['id']
      end

      def get_all_flavors(env)
        config = env[:machine].provider_config
        flavors_json = RestClient.get(config.openstack_compute_url + "/flavors",
          {"X-Auth-Token" => @token, :accept => :json})
        return JSON.parse(flavors_json)['flavors'].map { |fl| Item.new(fl['id'], fl['name']) }
      end

      def get_all_images(env)
        config = env[:machine].provider_config
        images_json = RestClient.get(config.openstack_compute_url + "/images",
          {"X-Auth-Token" => @token, :accept => :json})
        return JSON.parse(images_json)['images'].map { |im| Item.new(im['id'], im['name']) }
      end

      def create_server(env, name, image_ref, flavor_ref, keypair)
        config = env[:machine].provider_config
        server = RestClient.post(config.openstack_compute_url + "/servers", {
          :server => {
              :name => name,
              :imageRef => image_ref,
              :flavorRef => flavor_ref,
              :key_name => keypair
            }
          }.to_json,
          "X-Auth-Token" => @token,
          :accept => :json,
          :content_type => :json)
        return JSON.parse(server)['server']['id']
      end
    end

    class Item
      attr_accessor :id, :name
      def initialize(id, name)
        @id = id
        @name = name
      end
    end
  end
end
