require 'colorize'

module VagrantPlugins
  module Openstack
    module Action
      class AbstractAction
        def call(env)
          execute(env)
        # rubocop:disable Lint/RescueException
        rescue Exception => e
          puts I18n.t('vagrant_openstack.global_error').red
          raise e
        end
        # rubocop:enable Lint/RescueException
      end
    end
  end
end
