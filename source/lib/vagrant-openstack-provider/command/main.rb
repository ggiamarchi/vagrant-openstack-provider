module VagrantPlugins
  module Openstack
    module Command
      COMMANDS = [
        { name: :'image-list', file: 'image_list', clazz: 'ImageList' },
        { name: :'flavor-list', file: 'flavor_list', clazz: 'FlavorList' },
        { name: :'network-list', file: 'network_list', clazz: 'NetworkList' },
        { name: :'subnet-list', file: 'subnet_list', clazz: 'SubnetList' },
        { name: :'floatingip-list', file: 'floatingip_list', clazz: 'FloatingIpList' },
        { name: :'volume-list', file: 'volume_list', clazz: 'VolumeList' },
        { name: :'reset', file: 'reset', clazz: 'Reset' }
      ]

      class Main < Vagrant.plugin('2', :command)
        def self.synopsis
          I18n.t('vagrant_openstack.command.main_synopsis')
        end

        def initialize(argv, env)
          @env = env
          @main_args, @sub_command, @sub_args = split_main_and_subcommand(argv)
          @commands = Vagrant::Registry.new

          COMMANDS.each do |cmd|
            @commands.register(cmd[:name]) do
              require_relative cmd[:file]
              Command.const_get(cmd[:clazz])
            end
          end

          super(argv, env)
        end

        def execute
          command_class = @commands.get(@sub_command.to_sym) if @sub_command
          return usage unless command_class && @sub_command
          command_class.new(@sub_args, @env).execute(@sub_command)
        end

        def usage
          @env.ui.info I18n.t('vagrant_openstack.command.main_usage')
          @env.ui.info ''
          @env.ui.info I18n.t('vagrant_openstack.command.available_subcommands')
          @commands.each do |key, value|
            @env.ui.info "     #{key.to_s.ljust(20)} #{value.synopsis}"
          end
          @env.ui.info ''
        end
      end
    end
  end
end
