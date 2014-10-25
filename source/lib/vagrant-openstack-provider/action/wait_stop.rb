require 'log4r'
require 'timeout'

module VagrantPlugins
  module Openstack
    module Action
      class WaitForServerToStop
        def initialize(app, _env, retry_interval = 3, timeout = 200)
          @app    = app
          @logger = Log4r::Logger.new('vagrant_openstack::action::stop_server')
          @retry_interval = retry_interval
          @timeout = timeout
        end

        def call(env)
          if env[:machine].id
            env[:ui].info(I18n.t('vagrant_openstack.waiting_stop'))
            client = env[:openstack_client].nova
            timeout(@timeout) do
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
