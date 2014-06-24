require 'pathname'

require 'vagrant-openstack-provider/plugin'

module VagrantPlugins
  module Openstack
    lib_path = Pathname.new(File.expand_path('../vagrant-openstack-provider', __FILE__))
    autoload :Errors, lib_path.join('errors')

    # This initializes the i18n load path so that the plugin-specific
    # translations work.
    def self.init_i18n
      I18n.load_path << File.expand_path('locales/en.yml', source_root)
      I18n.reload!
    end

    # This initializes the logging so that our logs are outputted at
    # the same level as Vagrant core logs.
    def self.init_logging
      # Initialize logging
      level = nil
      begin
        level = Log4r.const_get(ENV['VAGRANT_LOG'].upcase)
      rescue NameError
        # This means that the logging constant wasn't found,
        # which is fine. We just keep `level` as `nil`. But
        # we tell the user.
        begin
          level = Log4r.const_get(ENV['VAGRANT_OPENSTACK_LOG'].upcase)
        rescue NameError
          level = nil
        end
      end

      # Some constants, such as "true" resolve to booleans, so the
      # above error checking doesn't catch it. This will check to make
      # sure that the log level is an integer, as Log4r requires.
      level = nil unless level.is_a?(Integer)

      # Set the logging level
      # logs as long as we have a valid level.
      if level
        logger = Log4r::Logger.new('vagrant_openstack')
        out = Log4r::Outputter.stdout
        out.formatter = Log4r::PatternFormatter.new(pattern: '%d | %5l | %m', date_pattern: '%Y-%m-%d %H:%M')
        logger.outputters = out
        logger.level = level
      end
    end

    # This returns the path to the source of this plugin.
    #
    # @return [Pathname]
    def self.source_root
      @source_root ||= Pathname.new(File.expand_path('../../', __FILE__))
    end
  end
end
