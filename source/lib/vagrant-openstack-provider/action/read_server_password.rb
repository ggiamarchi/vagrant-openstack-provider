require 'log4r'

require 'vagrant-openstack-provider/config_resolver'
require 'vagrant-openstack-provider/utils'
require 'vagrant-openstack-provider/action/abstract_action'

module VagrantPlugins
  module Openstack
    module Action
      # This action reads the server password for the machine and puts it into the
      # `config.winrm.password` key in the environment.

      class ReadServerPassword < AbstractAction
        def initialize(app, _env)
          @app    = app
          @logger = Log4r::Logger.new('vagrant_openstack::action::read_server_password')
        end

        def execute(env)          
          read_server_password(env)
          @app.call(env)
        end

        private

        def read_server_password(env)
          require 'openssl'
          require 'base64'
          machine=env[:machine]
          if VagrantPlugins::Openstack::Cap.need_dynamic_password_update(machine.config)
            @logger.info 'Reading server password from openstack'
            encoded_passwd_b64=env[:openstack_client].nova.get_server_password(env, machine.id)            
            if (encoded_passwd_b64==nil || encoded_passwd_b64=='')
              @logger.info "no password yet, the machine is not ready"
            else
              @logger.debug "encoded password b64 #{encoded_passwd_b64}"
              encoded_passwd=Base64.decode64(encoded_passwd_b64)
              ssh_key_path=env[:machine_ssh_info][:private_key_path]
              @logger.debug "key path #{ssh_key_path}"
              ssh_key = OpenSSL::PKey::RSA.new File.read(ssh_key_path)
              clear_passwd = ssh_key.private_decrypt(encoded_passwd)
              VagrantPlugins::Openstack::Cap.update_dynamic_password(machine.config,clear_passwd)
            end            
          end
        end
      end
    end
  end
end
