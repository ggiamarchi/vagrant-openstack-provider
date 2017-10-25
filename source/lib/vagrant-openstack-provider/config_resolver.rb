module VagrantPlugins
  module Openstack
    class ConfigResolver
      def initialize
        @logger = Log4r::Logger.new('vagrant_openstack::action::config_resolver')
      end

      def resolve_ssh_port(env)
        machine_config = env[:machine].config
        return machine_config.ssh.port if machine_config.ssh.port
        22
      end

      def resolve_flavor(env)
        @logger.info 'Resolving flavor'
        config = env[:machine].provider_config
        nova = env[:openstack_client].nova
        env[:ui].info(I18n.t('vagrant_openstack.finding_flavor'))
        flavors = nova.get_all_flavors(env)
        @logger.info "Finding flavor matching name '#{config.flavor}'"
        flavor = find_matching(flavors, config.flavor)
        fail Errors::NoMatchingFlavor unless flavor
        flavor
      end

      def resolve_image(env)
        @logger.info 'Resolving image'
        resolve_image_internal(env, env[:machine].provider_config.image)
      end

      def resolve_volume_boot_image(env)
        @logger.info 'Resolving image to create a volume from'
        resolve_image_internal(env, env[:machine].provider_config.volume_boot[:image])
      end

      def resolve_floating_ip(env)
        config = env[:machine].provider_config
        nova = env[:openstack_client].nova
        return config.floating_ip if config.floating_ip

        fail Errors::UnableToResolveFloatingIP if config.floating_ip_pool.nil? || config.floating_ip_pool.empty?

        @logger.debug 'Searching for available ips'
        free_ip = search_free_ip(config, nova, env)
        config.floating_ip = free_ip
        return free_ip unless free_ip.nil?

        @logger.debug 'Allocate new ip anyway'
        allocated_ip = allocate_ip(config, nova, env)
        config.floating_ip = allocated_ip
        return allocated_ip unless allocated_ip.nil?
      end

      def resolve_keypair(env)
        config = env[:machine].provider_config
        machine_config = env[:machine].config
        nova = env[:openstack_client].nova
        return nil unless machine_config.ssh.insert_key
        return config.keypair_name if config.keypair_name
        return nova.import_keypair_from_file(env, config.public_key_path) if config.public_key_path
        generate_keypair(env)
      end

      def resolve_networks(env)
        @logger.info 'Resolving network(s)'
        config = env[:machine].provider_config
        return [] if config.networks.nil? || config.networks.empty?
        env[:ui].info(I18n.t('vagrant_openstack.finding_networks'))
        return resolve_networks_without_network_service(env) unless env[:openstack_client].session.endpoints.key? :network

        all_networks = env[:openstack_client].neutron.get_all_networks(env)
        all_network_ids = all_networks.map(&:id)

        networks = []
        config.networks.each do |network|
          networks << resolve_network(network, all_networks, all_network_ids)
        end
        @logger.debug("Resolved networks : #{networks.to_json}")
        networks
      end

      def resolve_volume_boot(env)
        config = env[:machine].provider_config
        return nil if config.volume_boot.nil?
        return resolve_volume_without_volume_service(env, config.volume_boot, 'vda') unless env[:openstack_client].session.endpoints.key? :volume

        volume_list = env[:openstack_client].cinder.get_all_volumes(env)
        volume_ids = volume_list.map(&:id)

        @logger.debug(volume_list)

        volume = resolve_volume(config.volume_boot, volume_list, volume_ids)

        device = (volume[:device].nil?) ? 'vda' : volume[:device]
        size = (volume[:size].nil?) ? nil : volume[:size]
        delete_on_destroy = (volume[:delete_on_destroy].nil?) ? nil : volume[:delete_on_destroy]

        image = resolve_volume_boot_image(env) unless volume[:image].nil?
        image_id = (image.nil?) ? nil : image.id
        if image.nil?
          return { id: volume[:id], device: device }
        else
          { image: image_id, device: device, size: size, delete_on_destroy: delete_on_destroy }
        end
      end

      def resolve_volumes(env)
        @logger.info 'Resolving volume(s)'
        config = env[:machine].provider_config
        return [] if config.volumes.nil? || config.volumes.empty?
        env[:ui].info(I18n.t('vagrant_openstack.finding_volumes'))
        return resolve_volumes_without_volume_service(env) unless env[:openstack_client].session.endpoints.key? :volume

        volume_list = env[:openstack_client].cinder.get_all_volumes(env)
        volume_ids = volume_list.map(&:id)

        @logger.debug(volume_list)

        volumes = []
        config.volumes.each do |volume|
          volumes << resolve_volume(volume, volume_list, volume_ids)
        end
        @logger.debug("Resolved volumes : #{volumes.to_json}")
        volumes
      end

      def resolve_ssh_username(env)
        config = env[:machine].provider_config
        machine_config = env[:machine].config
        return machine_config.ssh.username if machine_config.ssh.username
        return config.ssh_username if config.ssh_username
        fail Errors::NoMatchingSshUsername
      end

      def resolve_security_groups(env)
        groups = []
        env[:machine].provider_config.security_groups.each do |group|
          case group
          when String
            groups << { name: group }
          when Hash
            groups << group
          end
        end unless env[:machine].provider_config.security_groups.nil?
        groups
      end

      private

      def resolve_image_internal(env, image_name)
        return nil if image_name.nil?

        nova = env[:openstack_client].nova
        env[:ui].info(I18n.t('vagrant_openstack.finding_image'))
        images = nova.get_all_images(env)
        image = find_matching(images, image_name)
        fail Errors::NoMatchingImage unless image
        image
      end

      def search_free_ip(config, nova, env)
        @logger.debug 'Retrieving all allocated floating ips on tenant'
        all_floating_ips = nova.get_all_floating_ips(env)
        all_floating_ips.each do |floating_ip|
          log_attach = floating_ip.instance_id ? "attached to #{floating_ip.instance_id}" : 'not attached'
          @logger.debug "#{floating_ip.ip} #{log_attach}" if config.floating_ip_pool.include? floating_ip.pool
          return floating_ip.ip if (config.floating_ip_pool.include? floating_ip.pool) && floating_ip.instance_id.nil?
        end unless config.floating_ip_pool_always_allocate
        @logger.debug 'No free ip found'
        nil
      end

      def allocate_ip(config, nova, env)
        allocation_error = nil
        config.floating_ip_pool.each do |floating_ip_pool|
          begin
            @logger.debug "Allocating ip in pool #{floating_ip_pool}"
            return nova.allocate_floating_ip(env, floating_ip_pool).ip
          rescue Errors::VagrantOpenstackError => e
            @logger.warn "Error allocating ip in pool #{floating_ip_pool} : #{e}"
            allocation_error = e
            next if e.extra_data[:code] == 404
            raise allocation_error
          end
        end
        @logger.warn 'Impossible to allocate a new IP'
        fail allocation_error
      end

      def generate_keypair(env)
        key = SSHKey.generate
        nova = env[:openstack_client].nova
        generated_keyname = nova.import_keypair(env, key.ssh_public_key)
        file_path = "#{env[:machine].data_dir}/#{generated_keyname}"
        File.write(file_path, key.private_key)
        File.chmod(0600, file_path)
        generated_keyname
      end

      def resolve_networks_without_network_service(env)
        config = env[:machine].provider_config
        networks = []
        config.networks.each do |network|
          case network
          when String
            env[:ui].info(I18n.t('vagrant_openstack.warn_network_identifier_is_assumed_to_be_an_id', network: network))
            networks << { uuid: network }
          when Hash
            fail Errors::ConflictNetworkNameId, network: network if network.key?(:name) && network.key?(:id)
            fail Errors::NetworkServiceUnavailable if network.key? :name
            if network.key?(:address)
              networks << { uuid: network[:id], fixed_ip: network[:address] }
            else
              networks << { uuid: network[:id] }
            end
          end
        end
        networks
      end

      def resolve_network(network, network_list, network_ids)
        return resolve_network_from_string(network, network_list) if network.is_a? String
        return resolve_network_from_hash(network, network_list, network_ids) if network.is_a? Hash
        fail Errors::InvalidNetworkObject, network: network
      end

      def resolve_network_from_string(network, network_list)
        found_network = find_matching(network_list, network)
        fail Errors::UnresolvedNetwork, network: network if found_network.nil?
        { uuid: found_network.id }
      end

      def resolve_network_from_hash(network, network_list, network_ids)
        if network.key?(:id)
          fail Errors::ConflictNetworkNameId, network: network if network.key?(:name)
          network_id = network[:id]
          fail Errors::UnresolvedNetworkId, id: network_id unless network_ids.include? network_id
        elsif network.key?(:name)
          network_list.each do |v|
            next unless v.name.eql? network[:name]
            fail Errors::MultipleNetworkName, name: network[:name] unless network_id.nil?
            network_id = v.id
          end
          fail Errors::UnresolvedNetworkName, name: network[:name] unless network_ids.include? network_id
        else
          fail Errors::ConflictNetworkNameId, network: network
        end
        return { uuid: network_id, fixed_ip: network[:address] } if network.key?(:address)
        { uuid: network_id }
      end

      def resolve_volumes_without_volume_service(env)
        env[:machine].provider_config.volumes.map { |volume| resolve_volume_without_volume_service(env, volume) }
      end

      def resolve_volume_without_volume_service(env, volume, default_device = nil)
        case volume
        when String
          env[:ui].info(I18n.t('vagrant_openstack.warn_volume_identifier_is_assumed_to_be_an_id', volume: volume))
          return { id: volume, device: default_device }
        when Hash
          fail Errors::ConflictVolumeNameId, volume: volume if volume.key?(:name) && volume.key?(:id)
          fail Errors::VolumeServiceUnavailable if volume.key? :name
          return { id: volume[:id], device: volume[:device] || default_device }
        end
        fail Errors::InvalidVolumeObject, volume: volume
      end

      def resolve_volume(volume, volume_list, volume_ids)
        return resolve_volume_from_string(volume, volume_list) if volume.is_a? String
        return resolve_volume_from_hash(volume, volume_list, volume_ids) if volume.is_a? Hash
        fail Errors::InvalidVolumeObject, volume: volume
      end

      def resolve_volume_from_string(volume, volume_list)
        found_volume = find_matching(volume_list, volume)
        fail Errors::UnresolvedVolume, volume: volume if found_volume.nil?
        { id: found_volume.id, device: nil }
      end

      def resolve_volume_from_hash(volume, volume_list, volume_ids)
        device = nil
        device = volume[:device] if volume.key?(:device)
        delete_on_destroy = (volume[:delete_on_destroy].nil?) ? 'true' : volume[:delete_on_destroy]

        volume_id = nil
        if volume.key?(:id)
          fail Errors::ConflictVolumeNameId, volume: volume if volume.key?(:name)
          check_boot_volume_conflict(volume)
          volume_id = volume[:id]
          fail Errors::UnresolvedVolumeId, id: volume_id unless volume_ids.include? volume_id
        elsif volume.key?(:name)
          volume_list.each do |v|
            next unless v.name.eql? volume[:name]
            fail Errors::MultipleVolumeName, name: volume[:name] unless volume_id.nil?
            check_boot_volume_conflict(volume)
            volume_id = v.id
          end
          fail Errors::UnresolvedVolumeName, name: volume[:name] unless volume_ids.include? volume_id
        elsif volume.key?(:image)
          fail Errors::UnresolvedVolume, volume: volume unless volume.key?(:size)
          fail Errors::ConflictBootVolume, volume: volume if volume.key?(:id)
          fail Errors::ConflictBootVolume, volume: volume if volume.key?(:name)
          return { image: volume[:image], device: device, size: volume[:size], delete_on_destroy: delete_on_destroy }
        else
          fail Errors::ConflictBootVolume, volume: volume
        end
        { id: volume_id, device: device }
      end

      def check_boot_volume_conflict(volume)
        fail Errors::ConflictBootVolume, volume: volume if volume.key?(:image) || volume.key?(:size) || volume.key?(:delete_on_destroy)
      end

      # This method finds any matching _thing_ from a list of names
      # in a collection of _things_. The first to match is the returned
      # one. Names in list can be a regexp, a partial match is chosen
      # as well.

      def find_matching(collection, name_or_names)
        name_or_names = [name_or_names] if name_or_names.class != Array
        name_or_names.each do |name|
          collection.each do |single|
            return single if single.id == name
            return single if single.name == name
            return single if name.is_a?(Regexp) && name =~ single.name
          end
        end
        @logger.error "No element of '#{name_or_names}' found in collection #{collection}"
        nil
      end
    end
  end
end
