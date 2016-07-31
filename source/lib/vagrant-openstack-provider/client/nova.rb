require 'log4r'
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
        flavors_json = get(env, "#{@session.endpoints[:compute]}/flavors/detail")
        JSON.parse(flavors_json)['flavors'].map do |fl|
          Flavor.new(fl['id'], fl['name'], fl['vcpus'], fl['ram'], fl['disk'])
        end
      end

      def get_all_floating_ips(env)
        ips_json = get(env, "#{@session.endpoints[:compute]}/os-floating-ips",
                       'X-Auth-Token' => @session.token,
                       :accept => :json)
        JSON.parse(ips_json)['floating_ips'].map { |n| FloatingIP.new(n['ip'], n['pool'], n['instance_id']) }
      end

      def allocate_floating_ip(env, pool)
        ips_json = post(env, "#{@session.endpoints[:compute]}/os-floating-ips",
                        {
                          pool: pool
                        }.to_json,
                        'X-Auth-Token' => @session.token,
                        :accept => :json,
                        :content_type => :json)
        floating_ip = JSON.parse(ips_json)['floating_ip']
        FloatingIP.new(floating_ip['ip'], floating_ip['pool'], floating_ip['instance_id'])
      end

      def get_all_images(env, headers = {})
        images_json = get(env, "#{@session.endpoints[:compute]}/images/detail", headers)
        JSON.parse(images_json)['images'].map do |fl|
          Image.new(
            fl['id'],
            fl['name'],
            'unknown',
            nil,
            fl['minRam'],
            fl['minDisk'],
            fl['metadata']
          )
        end
      end

      # Get detailed information about an image
      #
      # @param env [Hash] Vagrant action environment
      # @param image_id [String] Image UUID
      #
      # @return [Hash]
      def get_image_details(env, image_id)
        image_json = get(env, "#{@session.endpoints[:compute]}/images/#{image_id}")
        JSON.parse(image_json)['image']
      end

      def create_server(env, options)
        server = {}.tap do |s|
          s['name'] = options[:name]
          if options[:image_ref].nil?
            s['block_device_mapping'] = [{ volume_id: options[:volume_boot][:id],
                                           device_name: options[:volume_boot][:device] }] if options[:volume_boot].key?(:id)
            s['block_device_mapping_v2'] = [{ boot_index: '0',
                                              volume_size: options[:volume_boot][:size],
                                              uuid: options[:volume_boot][:image],
                                              device_name: options[:volume_boot][:device],
                                              source_type: 'image',
                                              destination_type: 'volume',
                                              delete_on_termination: options[:volume_boot][:delete_on_destroy] }]\
                                              if options[:volume_boot].key?(:image)
          else
            s['imageRef'] = options[:image_ref]
          end
          s['flavorRef'] = options[:flavor_ref]
          s['key_name'] = options[:keypair]
          s['availability_zone'] = options[:availability_zone] unless options[:availability_zone].nil?
          s['security_groups'] = options[:security_groups] unless options[:security_groups].nil?
          s['user_data'] = Base64.encode64(options[:user_data]) unless options[:user_data].nil?
          s['metadata'] = options[:metadata] unless options[:metadata].nil?
          s['networks'] = options[:networks] unless options[:networks].nil? || options[:networks].empty?
        end
        object = { server: server }
        object['os:scheduler_hints'] = options[:scheduler_hints] unless options[:scheduler_hints].nil?
        server = post(env, "#{@session.endpoints[:compute]}/servers", object.to_json)
        JSON.parse(server)['server']['id']
      end

      def delete_server(env, server_id)
        instance_exists do
          delete(env, "#{@session.endpoints[:compute]}/servers/#{server_id}")
        end
      end

      def suspend_server(env, server_id)
        instance_exists do
          change_server_state(env, server_id, :suspend)
        end
      end

      def resume_server(env, server_id)
        instance_exists do
          change_server_state(env, server_id, :resume)
        end
      end

      def stop_server(env, server_id)
        instance_exists do
          change_server_state(env, server_id, :stop)
        end
      end

      def start_server(env, server_id)
        instance_exists do
          change_server_state(env, server_id, :start)
        end
      end

      def get_server_details(env, server_id)
        instance_exists do
          server_details = get(env, "#{@session.endpoints[:compute]}/servers/#{server_id}")
          JSON.parse(server_details)['server']
        end
      end

      def add_floating_ip(env, server_id, floating_ip)
        instance_exists do
          check_floating_ip(env, floating_ip)

          post(env, "#{@session.endpoints[:compute]}/servers/#{server_id}/action",
               { addFloatingIp: { address: floating_ip } }.to_json)
        end
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
        instance_exists do
          keyname = get_server_details(env, server_id)['key_name']
          if keyname
            delete(env, "#{@session.endpoints[:compute]}/os-keypairs/#{keyname}") if keyname.start_with?('vagrant-generated-')
          end
        end
      end

      def get_floating_ip_pools(env)
        floating_ips = get(env, "#{@session.endpoints[:compute]}/os-floating-ip-pools")
        JSON.parse(floating_ips)['floating_ip_pools']
      end

      def get_floating_ips(env)
        floating_ips = get(env, "#{@session.endpoints[:compute]}/os-floating-ips")
        JSON.parse(floating_ips)['floating_ips']
      end

      def attach_volume(env, server_id, volume_id, device = nil)
        instance_exists do
          attachment = post(env, "#{@session.endpoints[:compute]}/servers/#{server_id}/os-volume_attachments",
                            {
                              volumeAttachment: {
                                volumeId: volume_id,
                                device: device
                              }
                            }.to_json)
          JSON.parse(attachment)['volumeAttachment']
        end
      end

      # List snapshot images associated with a particular server
      #
      # @param env [Hash] Vagrant action environment
      # @param server_id [String] Server UUID
      #
      # @return [Array<VagrantPlugins::Openstack::Domain::Image>]
      def list_snapshots(env, server_id)
        get_all_images(env, params: { server: server_id })
      end

      # Create a named snapsot for a given VM
      #
      # @param env [Hash] Vagrant action environment
      # @param server_id [String] Server UUID
      # @param snapshot_name [String]
      #
      # @return [void]
      def create_snapshot(env, server_id, snapshot_name)
        instance_exists do
          post(
            env,
            "#{@session.endpoints[:compute]}/servers/#{server_id}/action",
            { createImage: {
              name: snapshot_name,
              metadata: { vagrant_snapshot: 'true' }
            } }.to_json)
        end
      end

      # Delete an identified snapshot
      #
      # @param env [Hash] Vagrant action environment
      # @param snapshot_id [String] Snapshot UUID
      #
      # @return [void]
      def delete_snapshot(env, snapshot_id)
        delete(
          env,
          "#{@session.endpoints[:compute]}/images/#{snapshot_id}")
      end

      # Restore a VM to an identified snapshot
      #
      # @param env [Hash] Vagrant action environment
      # @param server_id [String] Server UUID
      # @param snapshot_id [String] Snapshot UUID
      #
      # @return [void]
      def restore_snapshot(env, server_id, snapshot_id)
        instance_exists do
          post(
            env,
            "#{@session.endpoints[:compute]}/servers/#{server_id}/action",
            { rebuild: { imageRef: snapshot_id } }.to_json)
        end
      end

      private

      VM_STATES =
          {
            suspend: 'suspend',
            resume: 'resume',
            start: 'os-start',
            stop: 'os-stop'
          }

      def instance_exists
        return yield
      rescue Errors::VagrantOpenstackError => e
        raise Errors::InstanceNotFound if e.extra_data[:code] == 404
        raise e
      end

      def change_server_state(env, server_id, new_state)
        post(env, "#{@session.endpoints[:compute]}/servers/#{server_id}/action",
             { :"#{VM_STATES[new_state.to_sym]}" => nil }.to_json)
      end

      def check_floating_ip(env, floating_ip)
        ip_details = get(env, "#{@session.endpoints[:compute]}/os-floating-ips")

        JSON.parse(ip_details)['floating_ips'].each do |ip|
          next unless ip['ip'] == floating_ip
          return if ip['instance_id'].nil?
          fail Errors::FloatingIPAlreadyAssigned, floating_ip: floating_ip
        end
        fail Errors::FloatingIPNotAvailable, floating_ip: floating_ip
      end
    end
  end
end
