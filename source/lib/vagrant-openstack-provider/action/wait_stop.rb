require 'log4r'
require 'timeout'

require 'vagrant-openstack-provider/action/abstract_action'

module VagrantPlugins
  module Openstack
    module Action
      class WaitForServerToStop < AbstractAction
        def initialize(app, _env, retry_interval = 3)
          @app    = app
          @logger = Log4r::Logger.new('vagrant_openstack::action::stop_server')
          @retry_interval = retry_interval
        end

        def execute(env)
          if env[:machine].id
            env[:ui].info(I18n.t('vagrant_openstack.waiting_stop'))
            client = env[:openstack_client].nova
            config = env[:machine].provider_config
            timeout(config.server_stop_timeout, Errors::Timeout) do
              while client.get_server_details(env, env[:machine].id)['status'] != 'SHUTOFF'
                sleep @retry_interval
                @logger.info('Waiting for server to stop')
              end
            end
          end
          @app.call(env)
        end
      end
    end
  end
end
