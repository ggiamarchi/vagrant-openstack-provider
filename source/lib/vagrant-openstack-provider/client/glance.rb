require 'log4r'
require 'restclient'
require 'json'

require 'vagrant-openstack-provider/client/http_utils'
require 'vagrant-openstack-provider/client/domain'

module VagrantPlugins
  module Openstack
    class GlanceClient
      include Singleton
      include VagrantPlugins::Openstack::HttpUtils
      include VagrantPlugins::Openstack::Domain

      def initialize
        @logger = Log4r::Logger.new('vagrant_openstack::glance')
        @session = VagrantPlugins::Openstack.session
      end

      def get_api_version_list(_env)
        json = RestClient.get(@session.endpoints[:image], 'X-Auth-Token' => @session.token, :accept => :json) do |response|
          log_response(response)
          case response.code
          when 200, 300
            response
          when 401
            fail Errors::AuthenticationFailed
          else
            fail Errors::VagrantOpenstackError, message: response.to_s
          end
        end
        JSON.parse(json)['versions']
      end

      def get_all_images(env)
        images_json = get(env, "#{@session.endpoints[:image]}/images")
        JSON.parse(images_json)['images'].map { |i| Image.new(i['id'], i['name'], i['visibility'], i['size'], i['min_ram'], i['min_disk']) }
      end
    end
  end
end
