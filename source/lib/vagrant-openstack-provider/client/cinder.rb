require 'log4r'
require 'restclient'
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
        JSON.parse(volumes_json)['volumes'].map do |v|
          name = v['display_name']
          name = v['name'] if name.nil? # To be compatible with cinder api v1 and v2
          Volume.new(v['id'], name, v['size'], v['status'], v['bootable'], v['instance_id'], v['device'])
        end
      end
    end
  end
end
