require 'log4r'
require 'json'

require 'vagrant-openstack-provider/client/http_utils'
require 'vagrant-openstack-provider/client/domain'

module VagrantPlugins
  module Openstack
    class CinderClient
      include Singleton
      include VagrantPlugins::Openstack::HttpUtils
      include VagrantPlugins::Openstack::Domain

      def initialize
        @logger = Log4r::Logger.new('vagrant_openstack::cinder')
        @session = VagrantPlugins::Openstack.session
      end

      def get_all_volumes(env)
        volumes_json = get(env, "#{@session.endpoints[:volume]}/volumes/detail")
        JSON.parse(volumes_json)['volumes'].map do |volume|
          name = volume['display_name']
          name = volume['name'] if name.nil? # To be compatible with cinder api v1 and v2
          case volume['attachments'].size
          when 0
            @logger.debug "No attachment found for volume #{volume['id']}"
          else
            attachment = volume['attachments'][0]
            server_id = attachment['server_id']
            device = attachment['device']
            @logger.warn "Found #{attachment.size} attachments for volume #{volume['id']} : " if attachment.size > 1
            @logger.debug "Attachment found for volume #{volume['id']} : #{attachment.to_json}"
          end
          Volume.new(volume['id'], name, volume['size'], volume['status'], volume['bootable'], server_id, device)
        end
      end
    end
  end
end
