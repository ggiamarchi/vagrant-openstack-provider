require 'log4r'
require 'restclient'
require 'json'

require 'vagrant-openstack-provider/client/request_logger'

module VagrantPlugins
  module Openstack
    class KeystoneClient
      include Singleton
      include VagrantPlugins::Openstack::HttpUtils::RequestLogger

      def initialize
        @logger = Log4r::Logger.new('vagrant_openstack::keystone')
        @session = VagrantPlugins::Openstack.session
      end

      def authenticate(env)
        @logger.info('Authenticating on Keystone')
        config = env[:machine].provider_config
        @logger.info(I18n.t('vagrant_openstack.client.authentication', project: config.tenant_name, user: config.username))

        post_body =
          {
            auth:
              {
                tenantName: config.tenant_name,
                passwordCredentials:
                  {
                    username: config.username,
                    password: '****'
                  }
              }
          }

        log_request(:POST, config.openstack_auth_url, post_body.to_json)

        post_body[:auth][:passwordCredentials][:password] = config.password

        authentication = RestClient.post(config.openstack_auth_url, post_body.to_json,
                                         content_type: :json,
                                         accept: :json) do |response|
          log_response(response)
          case response.code
          when 200
            response
          when 401
            fail Errors::AuthenticationFailed
          when 404
            fail Errors::BadAuthenticationEndpoint
          else
            fail Errors::VagrantOpenstackError, message: response.to_s
          end
        end

        access = JSON.parse(authentication)['access']
        response_token = access['token']
        @session.token = response_token['id']
        @session.project_id = response_token['tenant']['id']

        access['serviceCatalog']
      end
    end
  end
end
