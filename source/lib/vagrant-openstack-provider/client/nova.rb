require 'log4r'
require 'restclient'
require 'json'

module VagrantPlugins
  module Openstack
    class NovaClient
      def initialize
        @logger = Log4r::Logger.new('vagrant_openstack::nova')
        @session = VagrantPlugins::Openstack.session
      end

      def get_all_flavors(_env)
        flavors_json = RestClient.get("#{@session.endpoints[:compute]}/flavors", 'X-Auth-Token' => @session.token, :accept => :json)
        JSON.parse(flavors_json)['flavors'].map { |fl| Item.new(fl['id'], fl['name']) }
      end

      def get_all_images(_env)
        images_json = RestClient.get("#{@session.endpoints[:compute]}/images", 'X-Auth-Token' => @session.token, :accept => :json)
        JSON.parse(images_json)['images'].map { |im| Item.new(im['id'], im['name']) }
      end

      def create_server(_env, name, image_ref, flavor_ref, networks, keypair)
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
          :content_type => :json)

        JSON.parse(server)['server']['id']
      end

      def delete_server(_env, server_id)
        RestClient.delete(
          "#{@session.endpoints[:compute]}/servers/#{server_id}",
          'X-Auth-Token' => @session.token,
          :accept => :json)
      end

      def suspend_server(_env, server_id)
        RestClient.post(
          "#{@session.endpoints[:compute]}/servers/#{server_id}/action", '{ "suspend": null }',
          'X-Auth-Token' => @session.token,
          :accept => :json,
          :content_type => :json)
      end

      def resume_server(_env, server_id)
        # TODO(julienvey) check status before (if pause->unpause, if suspend->resume...)
        RestClient.post(
          "#{@session.endpoints[:compute]}/servers/#{server_id}/action", '{ "resume": null }',
          'X-Auth-Token' => @session.token,
          :accept => :json,
          :content_type => :json)
      end

      def stop_server(_env, server_id)
        RestClient.post(
          "#{@session.endpoints[:compute]}/servers/#{server_id}/action", '{ "os-stop": null }',
          'X-Auth-Token' => @session.token,
          :accept => :json,
          :content_type => :json)
      end

      def start_server(_env, server_id)
        RestClient.post(
          "#{@session.endpoints[:compute]}/servers/#{server_id}/action", '{ "os-start": null }',
          'X-Auth-Token' => @session.token,
          :accept => :json,
          :content_type => :json)
      end

      def get_server_details(_env, server_id)
        server_details = RestClient.get(
          "#{@session.endpoints[:compute]}/servers/#{server_id}",
          'X-Auth-Token' => @session.token,
          :accept => :json)
        JSON.parse(server_details)['server']
      end

      def add_floating_ip(env, server_id, floating_ip)
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
          :content_type => :json)
      end

      private

      def check_floating_ip(_env, floating_ip)
        ip_details = RestClient.get(
          "#{@session.endpoints[:compute]}/os-floating-ips",
          'X-Auth-Token' => @session.token,
          :accept => :json)

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
