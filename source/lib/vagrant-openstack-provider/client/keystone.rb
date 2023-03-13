require 'log4r'
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

        if config.identity_api_version == '2'
          post_body = get_body_2 config
          auth_url = get_auth_url_2 env
        elsif config.identity_api_version == '3'
          post_body = get_body_3 config
          auth_url = get_auth_url_3 env
        end

        headers = {
          content_type: :json,
          accept: :json
        }

        log_request(:POST, auth_url, post_body.to_json, headers)

        if config.identity_api_version == '2'
          post_body[:auth][:passwordCredentials][:password] = config.password
        elsif config.identity_api_version == '3'
          if config.openstack_auth_type != 'v3applicationcredential'
            post_body[:auth][:identity][:password][:user][:password] = config.password
          end
        end

        authentication = RestUtils.post(env, auth_url, post_body.to_json, headers) do |response|
          log_response(response)
          case response.code
          when 200
            response
          when 201
            response
          when 401
            fail Errors::AuthenticationFailed
          when 404
            fail Errors::BadAuthenticationEndpoint
          else
            fail Errors::VagrantOpenstackError, message: response.to_s
          end
        end

        if config.identity_api_version == '2'
          access = JSON.parse(authentication)['access']
          response_token = access['token']
          @session.token = response_token['id']
          @session.project_id = response_token['tenant']['id']
          return access['serviceCatalog']
        elsif config.identity_api_version == '3'
          body = JSON.parse(authentication)
          @session.token = authentication.headers[:x_subject_token]
          @session.project_id = body['token']['project']['id']
          return body['token']['catalog']
        end
      end

      private

      def get_body_2(config)
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
      end

      def get_body_3(config)
        body = {}
        if config.openstack_auth_type != 'v3applicationcredential'
          body = {
            auth:
            {
              identity: {
                methods: ['password'],
                password: {
                  user: {
                    name: config.username,
                    domain: {
                      name: config.user_domain_name
                    },
                    password: '****'
                  }
                }
              },
              scope: {
                project: {
                  name: config.project_name,
                  domain: { name: config.project_domain_name }
                }
              }
            }
          }
        else
          body = {
            auth:
            {
              identity: {
                methods: ['application_credential'],
                application_credential: {
                  id: config.app_cred_id,
                  secret: config.app_cred_secret
                }
              }
            }
          }
        end
        body
      end

      def get_auth_url_3(env)
        url = env[:machine].provider_config.openstack_auth_url
        return url if url.match(%r{/tokens/*$})
        "#{url}/auth/tokens"
      end

      def get_auth_url_2(env)
        url = env[:machine].provider_config.openstack_auth_url
        return url if url.match(%r{/tokens/*$})
        "#{url}/tokens"
      end
    end
  end
end
