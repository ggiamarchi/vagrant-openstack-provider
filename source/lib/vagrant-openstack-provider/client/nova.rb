require 'log4r'
require 'restclient'
require 'json'

require 'vagrant-openstack-provider/client/http_utils'
require 'vagrant-openstack-provider/client/domain'

module VagrantPlugins
  module Openstack
    class NovaClient
      include Singleton
      include VagrantPlugins::Openstack::HttpUtils
      include VagrantPlugins::Openstack::Domain

      def initialize
        @logger = Log4r::Logger.new('vagrant_openstack::nova')
        @session = VagrantPlugins::Openstack.session
      end

      def get_all_flavors(env)
        flavors_json = get(env, "#{@session.endpoints[:compute]}/flavors")
        JSON.parse(flavors_json)['flavors'].map { |fl| Item.new(fl['id'], fl['name']) }
      end

      def get_all_floating_ips(env)
        ips_json = get(env, "#{@session.endpoints[:compute]}/os-floating-ips",
                       'X-Auth-Token' => @session.token,
                       :accept => :json) { |res| handle_response(res) }
        JSON.parse(ips_json)['floating_ips'].map { |n| FloatingIP.new(n['ip'], n['pool'], n['instance_id']) }
      end

      def allocate_floating_ip(env, pool)
        ips_json = post(env, "#{@session.endpoints[:compute]}/os-floating-ips",
                        {
                          pool: pool
                        }.to_json,
                        'X-Auth-Token' => @session.token,
                        :accept => :json,
                        :content_type => :json) { |res| handle_response(res) }
        floating_ip = JSON.parse(ips_json)['floating_ip']
        FloatingIP.new(floating_ip['ip'], floating_ip['pool'], floating_ip['instance_id'])
      end

      def get_all_images(env)
        images_json = get(env, "#{@session.endpoints[:compute]}/images")
        JSON.parse(images_json)['images'].map { |fl| Item.new(fl['id'], fl['name']) }
      end

      def create_server(env, options)
        server = {}.tap do |s|
          s['name'] = options[:name]
          s['imageRef'] = options[:image_ref]
          s['flavorRef'] = options[:flavor_ref]
          s['key_name'] = options[:keypair]
          s['availability_zone'] = options[:availability_zone] unless options[:availability_zone].nil?
          unless options[:networks].nil? || options[:networks].empty?
            s['networks'] = []
            options[:networks].each do |uuid|
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

      def import_keypair(env, public_key)
        keyname = "vagrant-generated-#{Kernel.rand(36**8).to_s(36)}"

        key_details = post(env, "#{@session.endpoints[:compute]}/os-keypairs",
                           { keypair:
                             {
                               name: keyname,
                               public_key: public_key
                             }
                           }.to_json)
        JSON.parse(key_details)['keypair']['name']
      end

      def import_keypair_from_file(env, public_key_path)
        fail "File specified in public_key_path #{public_key_path} doesn't exist" unless File.exist?(public_key_path)
        file = File.open(public_key_path)
        import_keypair(env, file.read)
      end

      def delete_keypair_if_vagrant(env, server_id)
        keyname = get_server_details(env, server_id)['key_name']
        delete(env, "#{@session.endpoints[:compute]}/os-keypairs/#{keyname}") if keyname.start_with?('vagrant-generated-')
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
