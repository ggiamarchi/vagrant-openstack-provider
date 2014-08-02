require 'vagrant-openstack-provider/client/openstack'

module VagrantPlugins
  module Openstack
    module Command
      class AbstractCommand < Vagrant.plugin('2', :command)
        def initialize(argv, env)
          @env = env
          super(argv, env)
        end

        def execute(name)
          env = {}
          with_target_vms(nil, provider: :openstack) do |machine|
            env[:machine] = machine
            env[:ui] = @env.ui
          end

          VagrantPlugins::Openstack::Action::ConnectOpenstack.new(nil, env).call(env)

          cmd(name, @argv, env)
        end

        def cmd(_name, _argv, _env)
          fail 'Command not implemented. \'cmd\' method must be overridden in all subclasses'
        end
      end
    end
  end
end
