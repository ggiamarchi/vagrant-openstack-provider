module VagrantPlugins
  module Openstack
    module Catalog
      class OpenstackCatalog
        def initialize
          @logger = Log4r::Logger.new('vagrant_openstack::action::openstack_reader')
        end

        def read(env, catalog)
          config = env[:machine].provider_config
          client = env[:openstack_client]
          endpoints = client.session.endpoints
          @logger.info(I18n.t('vagrant_openstack.client.looking_for_available_endpoints'))
          @logger.info("Selecting endpoints matching region '#{config.region}'") unless config.region.nil?

          catalog.each do |service|
            se = service['endpoints']
            if config.identity_api_version == '2'
              get_endpoints_2(env, se, service, config, endpoints)
            elsif config.identity_api_version == '3'
              get_interfaces_3(se, service, config, endpoints)
            end
          end

          endpoints[:network] = choose_api_version('Neutron', 'openstack_network_url', 'v2') do
            client.neutron.get_api_version_list(env, :network)
          end if config.openstack_network_url.nil? && !endpoints[:network].nil?

          endpoints[:image] = choose_api_version('Glance', 'openstack_image_url', nil, false) do
            client.glance.get_api_version_list(env)
          end if config.openstack_image_url.nil? && !endpoints[:image].nil?
        end

        private

        def get_endpoints_2(env, se, service, config, endpoints)
          endpoint_type = config.endpoint_type
          if config.region.nil?
            if se.size > 1
              env[:ui].warn I18n.t('vagrant_openstack.client.multiple_endpoint', size: se.size, type: service['type'])
              env[:ui].warn "  => #{service['endpoints'][0][endpoint_type]}"
            end
            url = se[0][endpoint_type].strip
          else
            se.each do |endpoint|
              url = endpoint[endpoint_type].strip if endpoint['region'].eql? config.region
            end
          end
          endpoints[service['type'].to_sym] = url unless url.nil? || url.empty?
        end

        def get_interfaces_3(se, service, config, endpoints)
          url = nil
          se.each do |endpoint|
            next if endpoint['interface'] != config.interface_type
            if config.region.nil?
              url = endpoint['url']
              break
            elsif endpoint['region'] == config.region
              url = endpoint['url']
              break
            end
          end
          endpoints[service['type'].to_sym] = url unless url.nil? || url.empty?
        end

        def choose_api_version(service_name, url_property, version_prefix = nil, fail_if_not_found = true)
          versions = yield

          return versions.first['links'].first['href'] if version_prefix.nil?

          if versions.size == 1
            return versions.first['links'].first['href'] if versions.first['id'].start_with?(version_prefix)
            fail Errors::NoMatchingApiVersion, api_name: service_name, url_property: url_property, version_list: version_list if fail_if_not_found
          end

          version_list = ''
          versions.each do |version|
            return version['links'].first['href'] if version['id'].start_with?(version_prefix)
            links = version['links'].map { |l| l['href'] }
            version_list << "#{version['id'].ljust(6)} #{version['status'].ljust(10)} #{links}\n"
          end

          fail Errors::NoMatchingApiVersion, api_name: service_name, url_property: url_property, version_list: version_list if fail_if_not_found
          nil
        end
      end
    end
  end
end
