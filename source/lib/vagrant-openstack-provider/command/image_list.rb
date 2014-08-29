require 'vagrant-openstack-provider/command/utils'
require 'vagrant-openstack-provider/command/abstract_command'

module VagrantPlugins
  module Openstack
    module Command
      class ImageList < AbstractCommand
        include VagrantPlugins::Openstack::Command::Utils

        def self.synopsis
          I18n.t('vagrant_openstack.command.image_list_synopsis')
        end
        def cmd(name, argv, env)
          fail Errors::NoArgRequiredForCommand, cmd: name unless argv.size == 1
          images = env[:openstack_client].nova.get_all_images(env)
          display_item_list(env, images)
        end
      end
    end
  end
end
