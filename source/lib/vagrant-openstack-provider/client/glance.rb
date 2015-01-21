require 'log4r'
require 'json'

require 'vagrant-openstack-provider/client/http_utils'
require 'vagrant-openstack-provider/client/rest_utils'
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

      def get_api_version_list(env)
        json = RestUtils.get(env, @session.endpoints[:image],
                             'X-Auth-Token' => @session.token,
                             :accept => :json) do |response|
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

      # Endpoint /images exists on both v1 and v2 API
      # The attribute 'visibility' is used to detect
      # if the call has been made on v1 or v2
      #
      # In case of v2 we have all the needed information,
      # but in case of v1 we don't and we have to call
      # /images/detail to get full details
      #
      def get_all_images(env)
        images_json = get(env, "#{@session.endpoints[:image]}/images")
        images = JSON.parse(images_json)['images']

        return images if images.empty?

        is_v1 = false
        unless images[0].key? 'visibility'
          is_v1 = true
          images_json = get(env, "#{@session.endpoints[:image]}/images/detail")
          images = JSON.parse(images_json)['images']
        end

        images.map do |i|
          i['visibility'] = i['is_public'] ? 'public' : 'private' if is_v1
          Image.new(i['id'], i['name'], i['visibility'], i['size'], i['min_ram'], i['min_disk'])
        end
      end
    end
  end
end
