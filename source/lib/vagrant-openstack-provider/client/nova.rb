require 'log4r'
require 'restclient'
require 'json'

require 'vagrant-openstack-provider/client/http_utils'

module VagrantPlugins
  module Openstack
    class NovaClient
      include Singleton
      include VagrantPlugins::Openstack::HttpUtils

      def initialize
        @logger = Log4r::Logger.new('vagrant_openstack::nova')
        @session = VagrantPlugins::Openstack.session
      end

      def get_all_flavors(env)
        flavors_json = get(env, "#{@session.endpoints[:compute]}/flavors")
        JSON.parse(flavors_json)['flavors'].map { |fl| Item.new(fl['id'], fl['name']) }
      end

      def get_all_images(env)
        images_json = get(env, "#{@session.endpoints[:compute]}/images")
        JSON.parse(images_json)['images'].map { |fl| Item.new(fl['id'], fl['name']) }
      end

      def create_server(env, name, image_ref, flavor_ref, networks, keypair)
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
        server = post(env, "#{@session.endpoints[:compute]}/servers", { server: server }.to_json)
        JSON.parse(server)['server']['id']
      end

      def delete_server(env, server_id)
        delete(env, "#{@session.endpoints[:compute]}/servers/#{server_id}")
      end

      def suspend_server(env, server_id)
        change_server_state(env, server_id, :suspend)
      end

      def resume_server(env, server_id)
        # TODO(julienvey) check status before (if pause->unpause, if suspend->resume...)
        change_server_state(env, server_id, :resume)
      end

      def stop_server(env, server_id)
        change_server_state(env, server_id, :stop)
      end

      def start_server(env, server_id)
        change_server_state(env, server_id, :start)
      end

      def get_server_details(env, server_id)
        server_details = get(env, "#{@session.endpoints[:compute]}/servers/#{server_id}")
        JSON.parse(server_details)['server']
      end

      def add_floating_ip(env, server_id, floating_ip)
        check_floating_ip(env, floating_ip)

        post(env, "#{@session.endpoints[:compute]}/servers/#{server_id}/action",
             { addFloatingIp: { address: floating_ip } }.to_json)
      end

      private

      VM_STATES =
          {
            suspend: 'suspend',
            resume: 'resume',
            start: 'os-start',
            stop: 'os-stop'
          }

      def change_server_state(env, server_id, new_state)
        post(env, "#{@session.endpoints[:compute]}/servers/#{server_id}/action",
             { :"#{VM_STATES[new_state.to_sym]}" => nil }.to_json)
      end

      def check_floating_ip(env, floating_ip)
        ip_details = get(env, "#{@session.endpoints[:compute]}/os-floating-ips")

        JSON.parse(ip_details)['floating_ips'].each do |ip|
          next unless ip['ip'] == floating_ip
          return if ip['instance_id'].nil?
          fail "Floating IP #{floating_ip} already assigned to another server"
        end
        fail "Floating IP #{floating_ip} not available for this tenant"
      end
    end
  end
end
