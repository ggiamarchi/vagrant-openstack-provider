module VagrantPlugins
  module Openstack
    class Utils
      def initialize
        @logger = Log4r::Logger.new('vagrant_openstack::action::config_resolver')
      end

      def get_ip_address(env)
        return env[:machine].provider_config.floating_ip unless env[:machine].provider_config.floating_ip.nil?
        details = env[:openstack_client].nova.get_server_details(env, env[:machine].id)
        details['addresses'].each do |network|
          network[1].each do |network_detail|
            return network_detail['addr'] if network_detail['OS-EXT-IPS:type'] == 'floating'
          end
        end
        fail Errors::UnableToResolveIP
      end
    end
  end
end
