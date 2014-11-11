module VagrantPlugins
  module Openstack
    module Logging
      # This initializes the logging so that our logs are outputted at
      # the same level as Vagrant core logs.
      def self.init
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
    end
  end
end
