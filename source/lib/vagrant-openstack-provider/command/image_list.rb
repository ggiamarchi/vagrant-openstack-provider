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
          fail Errors::NoArgRequiredForCommand, cmd: name unless argv.size == 0
          rows = []
          headers = %w(Id Name)
          if env[:openstack_client].session.endpoints.key? :image
            images = env[:openstack_client].glance.get_all_images(env)
            images.each { |i| rows << [i.id, i.name, i.visibility, i.size.to_i / 1024 / 1024, i.min_ram, i.min_disk] }
            headers << ['Visibility', 'Size (Mo)', 'Min RAM (Go)', 'Min Disk (Go)']
            headers = headers.flatten
          else
            images = env[:openstack_client].nova.get_all_images(env)
            images.each { |image| rows << [image.id, image.name] }
          end
          display_table(env, headers, rows)
        end
      end
    end
  end
end
