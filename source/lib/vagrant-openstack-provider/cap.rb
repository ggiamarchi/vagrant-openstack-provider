module VagrantPlugins
  module Openstack
    module Cap
      @logger = Log4r::Logger.new('vagrant_openstack::capability::winrm_info')

      def self.winrm_info(machine)
        # if we need dynamic password update from openstack?
        if need_dynamic_password_update(machine.config)
          @logger.info "config.winrm.password needs dynamic update, will retrieve it from openstack"
          env = machine.action('read_server_password', lock: false)
          # is password now updated?
          if need_dynamic_password_update(env[:machine].config)
            # if we have no server password yet in openstack, we are not ready. Return nil to tell that.
            return nil         
          end
        else
          @logger.info "config.winrm.password is set to a non-dynamic value (i.e. not ':dynamic'), keeping it"
        end
        # if ok with password, return just nil values for host and port, so that winrm executes its default code.
        return {
          host: nil,
          port: nil
        }
      end
      
      def self.need_dynamic_password_update(config)
        return config.winrm.password == :dynamic
      end
      
      def self.update_dynamic_password(config,new_password)
        if config.winrm.password == :dynamic
          config.winrm.password=new_password
          @logger.info "config.winrm.password changed to the dynamic one from openstack"
        end
      end
    end
  end
end
