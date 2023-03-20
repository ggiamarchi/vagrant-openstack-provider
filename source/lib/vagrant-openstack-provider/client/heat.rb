require 'log4r'
require 'json'

require 'vagrant-openstack-provider/client/http_utils'
require 'vagrant-openstack-provider/client/domain'

module VagrantPlugins
  module Openstack
    class HeatClient
      include Singleton
      include VagrantPlugins::Openstack::HttpUtils
      include VagrantPlugins::Openstack::Domain

      def initialize
        @logger = Log4r::Logger.new('vagrant_openstack::glance')
        @session = VagrantPlugins::Openstack.session
      end

      def create_stack(env, options)
        stack = {}.tap do |s|
          s['stack_name'] = options[:name] if options[:name]
          s['template'] = options[:template]
          s['environment'] = options[:environment]
        end
        stack_res = post(env, "#{@session.endpoints[:orchestration]}/stacks", stack.to_json)
        JSON.parse(stack_res)['stack']['id']
      end

      def get_stack_details(env, stack_name, stack_id)
        stack_exists do
          server_details = get(env, "#{@session.endpoints[:orchestration]}/stacks/#{stack_name}/#{stack_id}")
          JSON.parse(server_details)['stack']
        end
      end

      def delete_stack(env, stack_name, stack_id)
        stack_exists do
          delete(env, "#{@session.endpoints[:orchestration]}/stacks/#{stack_name}/#{stack_id}")
        end
      end

      def stack_exists
        return yield
      rescue Errors::VagrantOpenstackError => e
        raise Errors::StackNotFound if e.extra_data[:code] == 404
        raise e
      end
    end
  end
end
