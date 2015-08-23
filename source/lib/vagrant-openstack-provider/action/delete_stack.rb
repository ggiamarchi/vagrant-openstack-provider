require 'log4r'
require 'socket'
require 'timeout'
require 'sshkey'
require 'yaml'

require 'vagrant-openstack-provider/config_resolver'
require 'vagrant-openstack-provider/utils'
require 'vagrant-openstack-provider/action/abstract_action'
require 'vagrant/util/retryable'

module VagrantPlugins
  module Openstack
    module Action
      class DeleteStack < AbstractAction
        def initialize(app, _env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_openstack::action::delete_stack')
        end

        def execute(env)
          @logger.info 'Start delete stacks action'

          heat = env[:openstack_client].heat

          list_stack_files(env).each do |stack|
            env[:ui].info(I18n.t('vagrant_openstack.delete_stack'))
            env[:ui].info(" -- Stack Name : #{stack[:name]}")
            env[:ui].info(" -- Stack ID   : #{stack[:id]}")

            heat.delete_stack(env, stack[:name], stack[:id])

            waiting_for_stack_to_be_deleted(env, stack[:name], stack[:id])
          end

          # This will remove all files in the .vagrant instance directory
          env[:machine].id = nil

          @app.call(env)
        end

        private

        def list_stack_files(env)
          stack_files = []
          Dir.glob("#{env[:machine].data_dir}/stack_*_id") do |stack_file|
            file_name = stack_file.split('/')[-1]
            stack_files << {
              name: file_name[6, (file_name.length) - 9],
              id: File.read("#{stack_file}")
            }
          end
          stack_files
        end

        def waiting_for_stack_to_be_deleted(env, stack_name, stack_id, retry_interval = 3)
          @logger.info "Waiting for the stack with id #{stack_id} to be deleted..."
          env[:ui].info(I18n.t('vagrant_openstack.waiting_for_stack_deleted'))
          config = env[:machine].provider_config
          timeout(config.stack_delete_timeout, Errors::Timeout) do
            stack_status = 'DELETE_IN_PROGRESS'
            until stack_status == 'DELETE_COMPLETE'
              @logger.debug('Waiting for stack to be DELETED')
              stack_status = env[:openstack_client].heat.get_stack_details(env, stack_name, stack_id)['stack_status']
              fail Errors::StackStatusError, stack: stack_id if stack_status == 'DELETE_FAILED'
              sleep retry_interval
            end
          end
        end
      end
    end
  end
end
