module VagrantPlugins
  module Openstack
    class Utils
      def initialize
        @logger = Log4r::Logger.new('vagrant_openstack::action::config_resolver')
      end

      def get_ip_address(env)
        addresses = env[:openstack_client].nova.get_server_details(env, env[:machine].id)['addresses']
        addresses.each do |_, network|
          network.each do |network_detail|
            return network_detail['addr'] if network_detail['OS-EXT-IPS:type']  =~ /(^floating$|^fixed$)/
          end
        end
        fail Errors::UnableToResolveIP if addresses.size == 0
        if addresses.size == 1
          net_addresses = addresses.first[1]
        else
          first_network = env[:machine].provider_config.networks[0]
          if first_network.is_a? String
            net_addresses = addresses[first_network]
          else
            net_addresses = addresses[first_network[:name]]
          end
        end
        fail Errors::UnableToResolveIP if net_addresses.size == 0
        net_addresses[0]['addr']
      end
    end
  end
end
