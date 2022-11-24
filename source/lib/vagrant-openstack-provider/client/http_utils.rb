require 'log4r'
require 'json'

require 'vagrant-openstack-provider/client/keystone'
require 'vagrant-openstack-provider/client/request_logger'
require 'vagrant-openstack-provider/client/rest_utils'

module VagrantPlugins
  module Openstack
    module HttpUtils
      include VagrantPlugins::Openstack::HttpUtils::RequestLogger

      def get(env, url, headers = {})
        calling_method = caller[0][/`.*'/][1..-2]
        @logger.debug("#{calling_method} - start")

        headers.merge!('X-Auth-Token' => @session.token, :accept => :json)

        log_request(:GET, url, headers)

        authenticated(env) do
          res = RestUtils.get(env, url, headers)
          handle_response(res)
          @logger.debug("#{calling_method} - end")
          res
        end
      end

      def post(env, url, body = nil, headers = {})
        calling_method = caller[0][/`.*'/][1..-2]
        @logger.debug("#{calling_method} - start")

        headers.merge!('X-Auth-Token' => @session.token, :accept => :json, :content_type => :json)

        log_request(:POST, url, body, headers)

        authenticated(env) do
          res = RestUtils.post(env, url, body, headers)
          handle_response(res)
          @logger.debug("#{calling_method} - end")
          res
        end
      end

      def delete(env, url, headers = {})
        calling_method = caller[0][/`.*'/][1..-2]
        @logger.debug("#{calling_method} - start")

        headers.merge!('X-Auth-Token' => @session.token, :accept => :json, :content_type => :json)

        log_request(:DELETE, url, headers)

        authenticated(env) do
          res = RestUtils.delete(env, url, headers)
          handle_response(res)
          @logger.debug("#{calling_method} - end")
          res
        end
      end

      def get_api_version_list(env, service_type)
        url = @session.endpoints[service_type]
        headers = { 'X-Auth-Token' => @session.token, :accept => :json }
        log_request(:GET, url, headers)

        response = RestUtils.get(env, url, headers)
        log_response(response)
        case response.code
        when 200, 300
          json = response
        when 401
          fail Errors::AuthenticationFailed
        else
          fail Errors::VagrantOpenstackError, message: response.to_s
        end

        JSON.parse(json)['versions']
      end

      private

      ERRORS =
          {
            '400' => 'badRequest',
            '404' => 'itemNotFound',
            '409' => 'conflictingRequest'
          }

      def handle_response(response)
        log_response(response)
        case response.code
        when 200, 201, 202, 204
          response
        when 401
          fail Errors::AuthenticationRequired
        when 400, 404, 409
          message = JSON.parse(response.to_s)[ERRORS[response.code.to_s]]['message']
          fail Errors::VagrantOpenstackError, message: message, code: response.code
        else
          fail Errors::VagrantOpenstackError, message: response.to_s, code: response.code
        end
      end

      def authenticated(env)
        nb_retry = 0
        begin
          return yield
        rescue Errors::AuthenticationRequired => e
          nb_retry += 1
          env[:ui].warn(e)
          env[:ui].warn(I18n.t('vagrant_openstack.trying_authentication'))
          env[:openstack_client].keystone.authenticate(env)
          retry if nb_retry < 3
          raise e
        end
      end
    end
  end
end
