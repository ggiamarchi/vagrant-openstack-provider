require 'log4r'
require 'restclient'
require 'json'

module VagrantPlugins
  module Openstack
    class KeystoneClient
      include Singleton

      def initialize
        @logger = Log4r::Logger.new('vagrant_openstack::keystone')
        @session = VagrantPlugins::Openstack.session
      end

      def authenticate(env)
        @logger.info('Authenticating on Keystone')
        config = env[:machine].provider_config
        @logger.info(I18n.t('vagrant_openstack.client.authentication', project: config.tenant_name, user: config.username))

        authentication = RestClient.post(
            config.openstack_auth_url,
            {
              auth:
              {
                tenantName: config.tenant_name,
                passwordCredentials:
                  {
                    username: config.username,
                    password: config.password
                  }
              }
            }.to_json,
            content_type: :json,
            accept: :json)

        access = JSON.parse(authentication)['access']

        read_endpoint_catalog(env, access['serviceCatalog'])
        override_endpoint_catalog_with_user_config(env)
        log_endpoint_catalog

        response_token = access['token']
        @session.token = response_token['id']
        @session.project_id = response_token['tenant']['id']
      end

      private

      def read_endpoint_catalog(env, catalog)
        @logger.info(I18n.t('vagrant_openstack.client.looking_for_available_endpoints'))

        catalog.each do |service|
          se = service['endpoints']
          if se.size > 1
            env[:ui].warn I18n.t('vagrant_openstack.client.multiple_endpoint', size: se.size, type: service['type'])
            env[:ui].warn "  => #{service['endpoints'][0]['publicURL']}"
          end
          url = se[0]['publicURL'].strip
          @session.endpoints[service['type'].to_sym] = url unless url.empty?
        end
      end

      def override_endpoint_catalog_with_user_config(env)
        config = env[:machine].provider_config
        @session.endpoints[:compute] = config.openstack_compute_url unless config.openstack_compute_url.nil?
        @session.endpoints[:network] = config.openstack_network_url unless config.openstack_network_url.nil?
      end

      def log_endpoint_catalog
        @session.endpoints.each do |key, value|
          @logger.info(" -- #{key.to_s.ljust 15}: #{value}")
        end
      end
    end
  end
end
