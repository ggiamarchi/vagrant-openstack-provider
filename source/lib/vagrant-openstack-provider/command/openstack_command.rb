require 'vagrant-openstack-provider/command/utils'
require 'vagrant-openstack-provider/command/abstract_command'

module VagrantPlugins
  module Openstack
    module Command
      class OpenstackCommand < AbstractCommand
        include VagrantPlugins::Openstack::Command::Utils

        def before_cmd(_name, _argv, env)
          VagrantPlugins::Openstack::Action::ConnectOpenstack.new(nil, env).call(env)
        end
      end
    end
  end
end
