require 'vagrant-openstack-provider/client/openstack'

module VagrantPlugins
  module Openstack
    module Command
      class AbstractCommand < Vagrant.plugin('2', :command)
        def initialize(argv, env)
          @env = env
          super(normalize_args(argv), env)
        end

        def execute(name)
          env = {}
          with_target_vms(nil, provider: :openstack) do |machine|
            env[:machine] = machine
            env[:ui] = @env.ui
          end

          VagrantPlugins::Openstack::Action::ConnectOpenstack.new(nil, env).call(env)

          cmd(name, @argv, env)
          @env.ui.info('')
        # rubocop:disable Lint/RescueException
        rescue Errors::VagrantOpenstackError => e
          raise e
        rescue Exception => e
          puts I18n.t('vagrant_openstack.global_error').red unless e.message && e.message.start_with?('Catched Error:')
          raise e
        end
        # rubocop:enable Lint/RescueException

        #
        # Before Vagrant 1.5, args list ends with an extra arg '--'. It removes it if present.
        #
        def normalize_args(args)
          return args if args.nil?
          args.pop if args.size > 0 && args.last == '--'
          args
        end

        def cmd(_name, _argv, _env)
          fail 'Command not implemented. \'cmd\' method must be overridden in all subclasses'
        end
      end
    end
  end
end
