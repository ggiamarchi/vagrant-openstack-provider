require 'log4r'
require 'restclient'
require 'json'

require 'vagrant-openstack-provider/client/openstack'
require 'vagrant-openstack-provider/client/request_logger'

module VagrantPlugins
  module Openstack
    module Action
      class ConnectOpenstack
        include VagrantPlugins::Openstack::HttpUtils::RequestLogger

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_openstack::action::connect_openstack')
          env[:openstack_client] = VagrantPlugins::Openstack
        end

        def call(env)
          client = env[:openstack_client]
          if client.session.token.nil?
            catalog = client.keystone.authenticate(env)
            read_endpoint_catalog(env, catalog)
            override_endpoint_catalog_with_user_config(env)
            log_endpoint_catalog(env)
          end
          @app.call(env) unless @app.nil?
        end

        private

        def read_endpoint_catalog(env, catalog)
          config = env[:machine].provider_config
          client = env[:openstack_client]
          @logger.info(I18n.t('vagrant_openstack.client.looking_for_available_endpoints'))

          catalog.each do |service|
            se = service['endpoints']
            if se.size > 1
              env[:ui].warn I18n.t('vagrant_openstack.client.multiple_endpoint', size: se.size, type: service['type'])
              env[:ui].warn "  => #{service['endpoints'][0]['publicURL']}"
            end
            url = se[0]['publicURL'].strip
            client.session.endpoints[service['type'].to_sym] = url unless url.empty?
          end

          read_network_api_version(env) if config.openstack_network_url.nil?
        end

        def read_network_api_version(env)
          client = env[:openstack_client]
          versions = client.neutron.get_api_version_list(env)
          if versions.size > 1
            version_list = ''
            versions.each do |version|
              links = version['links'].map { |l| l['href'] }
              version_list << "#{version['id'].ljust(6)} #{version['status'].ljust(10)} #{links}\n"
            end
            fail Errors::MultipleApiVersion, api_name: 'Neutron', url_property: 'openstack_network_url', version_list: version_list
          end
          client.session.endpoints[:network] = versions.first['links'].first['href']
        end

        def override_endpoint_catalog_with_user_config(env)
          client = env[:openstack_client]
          config = env[:machine].provider_config
          client.session.endpoints[:compute] = config.openstack_compute_url unless config.openstack_compute_url.nil?
          client.session.endpoints[:network] = config.openstack_network_url unless config.openstack_network_url.nil?
        end

        def log_endpoint_catalog(env)
          env[:openstack_client].session.endpoints.each do |key, value|
            @logger.info(" -- #{key.to_s.ljust 15}: #{value}")
          end
        end
      end
    end
  end
end
