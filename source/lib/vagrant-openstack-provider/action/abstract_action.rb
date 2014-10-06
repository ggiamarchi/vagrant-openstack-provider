require 'colorize'

module VagrantPlugins
  module Openstack
    module Action
      class AbstractAction
        def call(env)
          execute(env)
        # rubocop:disable Lint/RescueException
        # rubocop:disable Style/SpecialGlobalVars
        rescue Exception
          puts I18n.t('vagrant_openstack.global_error').red
          raise $!, "Catched Error: #{$!}", $!.backtrace
        end
        # rubocop:enable Lint/RescueException
        # rubocop:enable Style/SpecialGlobalVars
      end
    end
  end
end
