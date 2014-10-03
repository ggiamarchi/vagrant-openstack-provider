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
        config = env[:machine].provider_config
        return nil if config.image.nil?
        nova = env[:openstack_client].nova
        env[:ui].info(I18n.t('vagrant_openstack.finding_image'))
        images = nova.get_all_images(env)
        @logger.info "Finding image matching name '#{config.image}'"
        image = find_matching(images, config.image)
        fail Errors::NoMatchingImage unless image
        image
      end

      def resolve_floating_ip(env)
        config = env[:machine].provider_config
        nova = env[:openstack_client].nova
        return config.floating_ip if config.floating_ip
        floating_ips = nova.get_all_floating_ips(env)
        fail Errors::UnableToResolveFloatingIP unless config.floating_ip_pool
        floating_ips.each do |single|
          return single.ip if single.pool == config.floating_ip_pool && single.instance_id.nil?
        end unless config.floating_ip_pool_always_allocate
        nova.allocate_floating_ip(env, config.floating_ip_pool).ip
      end

      def resolve_keypair(env)
        config = env[:machine].provider_config
        nova = env[:openstack_client].nova
        return config.keypair_name if config.keypair_name
        return nova.import_keypair_from_file(env, config.public_key_path) if config.public_key_path
        generate_keypair(env)
      end

      def resolve_networks(env)
        @logger.info 'Resolving network(s)'
        config = env[:machine].provider_config
        return [] if config.networks.nil? || config.networks.empty?
        env[:ui].info(I18n.t('vagrant_openstack.finding_networks'))

        private_networks = env[:openstack_client].neutron.get_private_networks(env)
        private_network_ids = private_networks.map { |n| n.id }

        networks = []
        config.networks.each do |network|
          if private_network_ids.include?(network)
            networks << network
            next
          end
          net_id = nil
          private_networks.each do |n| # Bad algorithm complexity, but here we don't care...
            next unless n.name.eql? network
            fail "Multiple networks with name '#{n.id}'" unless net_id.nil?
            net_id = n.id
          end
          fail "No matching network with name '#{network}'" if net_id.nil?
          networks << net_id
        end
        networks
      end

      def resolve_volume_boot(env)
        @logger.info 'Resolving image'
        config = env[:machine].provider_config
        return nil if config.volume_boot.nil?

        volume_list = env[:openstack_client].cinder.get_all_volumes(env)
        volume_ids = volume_list.map { |v| v.id }

        @logger.debug(volume_list)

        volume = resolve_volume(config.volume_boot, volume_list, volume_ids)
        device = volume[:device].nil? ? 'vda' : volume[:device]

        { id: volume[:id], device: device }
      end

      def resolve_volumes(env)
        @logger.info 'Resolving volume(s)'
        config = env[:machine].provider_config
        return [] if config.volumes.nil? || config.volumes.empty?
        env[:ui].info(I18n.t('vagrant_openstack.finding_volumes'))

        volume_list = env[:openstack_client].cinder.get_all_volumes(env)
        volume_ids = volume_list.map { |v| v.id }

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

      private

      def generate_keypair(env)
        key = SSHKey.generate
        nova = env[:openstack_client].nova
        generated_keyname = nova.import_keypair(env, key.ssh_public_key)
        File.write("#{env[:machine].data_dir}/#{generated_keyname}", key.private_key)
        generated_keyname
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
        if volume.key?(:id)
          fail Errors::ConflictVolumeNameId, volume: volume if volume.key?(:name)
          volume_id = volume[:id]
          fail Errors::UnresolvedVolumeId, id: volume_id unless volume_ids.include? volume_id
        elsif volume.key?(:name)
          volume_list.each do |v|
            next unless v.name.eql? volume[:name]
            fail Errors::MultipleVolumeName, name: volume[:name] unless volume_id.nil?
            volume_id = v.id
          end
          fail Errors::UnresolvedVolumeName, name: volume[:name] unless volume_ids.include? volume_id
        else
          fail Errors::ConflictVolumeNameId, volume: volume
        end
        { id: volume_id, device: device }
      end

      # This method finds a matching _thing_ in a collection of
      # _things_. This works matching if the ID or NAME equals to
      # `name`. Or, if `name` is a regexp, a partial match is chosen
      # as well.
      def find_matching(collection, name)
        collection.each do |single|
          return single if single.id == name
          return single if single.name == name
          return single if name.is_a?(Regexp) && name =~ single.name
        end
        @logger.error "Element '#{name}' not found in collection #{collection}"
        nil
      end
    end
  end
end
