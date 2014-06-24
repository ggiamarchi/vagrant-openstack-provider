require 'log4r'
require 'restclient'
require 'json'

require 'vagrant-openstack-provider/client/utils'

module VagrantPlugins
  module Openstack
    class NovaClient
      include Singleton
      include VagrantPlugins::Openstack::Utils

      def initialize
        @logger = Log4r::Logger.new('vagrant_openstack::nova')
        @session = VagrantPlugins::Openstack.session
      end

      def get_all_flavors(env)
        authenticated(env) do
          flavors_json = RestClient.get("#{@session.endpoints[:compute]}/flavors",
                                        'X-Auth-Token' => @session.token,
                                        :accept => :json) { |res| handle_response(res) }

          return JSON.parse(flavors_json)['flavors'].map { |fl| Item.new(fl['id'], fl['name']) }
        end
      end

      def get_all_images(env)
        authenticated(env) do
          images_json = RestClient.get(
            "#{@session.endpoints[:compute]}/images",
            'X-Auth-Token' => @session.token, :accept => :json) { |res| handle_response(res) }

          JSON.parse(images_json)['images'].map { |im| Item.new(im['id'], im['name']) }
        end
      end

      def create_server(env, name, image_ref, flavor_ref, networks, keypair)
        authenticated(env) do
          server = {}.tap do |s|
            s['name'] = name
            s['imageRef'] = image_ref
            s['flavorRef'] = flavor_ref
            s['key_name'] = keypair
            unless networks.nil? || networks.empty?
              s['networks'] = []
              networks.each do |uuid|
                s['networks'] << { uuid: uuid }
              end
            end
          end

          server = RestClient.post(
            "#{@session.endpoints[:compute]}/servers", { server: server }.to_json,
            'X-Auth-Token' => @session.token,
            :accept => :json,
            :content_type => :json) { |res| handle_response(res) }

          JSON.parse(server)['server']['id']
        end
      end

      def delete_server(env, server_id)
        authenticated(env) do
          RestClient.delete(
            "#{@session.endpoints[:compute]}/servers/#{server_id}",
            'X-Auth-Token' => @session.token,
            :accept => :json) { |res| handle_response(res) }
        end
      end

      def suspend_server(env, server_id)
        authenticated(env) do
          RestClient.post(
            "#{@session.endpoints[:compute]}/servers/#{server_id}/action", '{ "suspend": null }',
            'X-Auth-Token' => @session.token,
            :accept => :json,
            :content_type => :json) { |res| handle_response(res) }
        end
      end

      def resume_server(env, server_id)
        # TODO(julienvey) check status before (if pause->unpause, if suspend->resume...)
        authenticated(env) do
          RestClient.post(
            "#{@session.endpoints[:compute]}/servers/#{server_id}/action", '{ "resume": null }',
            'X-Auth-Token' => @session.token,
            :accept => :json,
            :content_type => :json) { |res| handle_response(res) }
        end
      end

      def stop_server(env, server_id)
        authenticated(env) do
          RestClient.post(
            "#{@session.endpoints[:compute]}/servers/#{server_id}/action", '{ "os-stop": null }',
            'X-Auth-Token' => @session.token,
            :accept => :json,
            :content_type => :json) { |res| handle_response(res) }
        end
      end

      def start_server(env, server_id)
        authenticated(env) do
          RestClient.post(
            "#{@session.endpoints[:compute]}/servers/#{server_id}/action", '{ "os-start": null }',
            'X-Auth-Token' => @session.token,
            :accept => :json,
            :content_type => :json) { |res| handle_response(res) }
        end
      end

      def get_server_details(env, server_id)
        authenticated(env) do
          server_details = RestClient.get(
            "#{@session.endpoints[:compute]}/servers/#{server_id}",
            'X-Auth-Token' => @session.token,
            :accept => :json) { |res| handle_response(res) }

          return JSON.parse(server_details)['server']
        end
      end

      def add_floating_ip(env, server_id, floating_ip)
        authenticated(env) do
          check_floating_ip(env, floating_ip)
          RestClient.post(
            "#{@session.endpoints[:compute]}/servers/#{server_id}/action",
            {
              addFloatingIp:
              {
                address: floating_ip
              }
            }.to_json,
            'X-Auth-Token' => @session.token,
            :accept => :json,
            :content_type => :json) { |res| handle_response(res) }
        end
      end

      private

      def check_floating_ip(_env, floating_ip)
        ip_details = RestClient.get(
          "#{@session.endpoints[:compute]}/os-floating-ips",
          'X-Auth-Token' => @session.token,
          :accept => :json) { |res| handle_response(res) }

        JSON.parse(ip_details)['floating_ips'].each do |ip|
          next unless ip['ip'] == floating_ip
          return if ip['instance_id'].nil?
          fail "Floating IP #{floating_ip} already assigned to another server"
        end
        fail "Floating IP #{floating_ip} not available for this tenant"
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
