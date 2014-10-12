require 'log4r'

module VagrantPlugins
  module Openstack
    module Action
      class WaitForServerToBeAccessible
        def initialize(app, env, resolver = nil)
          @app     = app
          @ssh     = Vagrant::Action::Builtin::SSHRun.new(app, env)
          @logger  = Log4r::Logger.new('vagrant_openstack::action::wait_accessible')
          if resolver.nil?
            @resolver = VagrantPlugins::Openstack::ConfigResolver.new
          else
            @resolver = resolver
          end
        end

        def call(env)
          waiting_for_server_to_be_reachable(env)
          @logger.info 'The server is ready'
          env[:ui].info(I18n.t('vagrant_openstack.ready'))
          @app.call(env)
        end

        private

        def waiting_for_server_to_be_reachable(env)
          return if env[:interrupted]
          ssh_timeout = env[:machine].provider_config.ssh_timeout
          return if server_is_reachable?(env, ssh_timeout)
          env[:ui].error(I18n.t('vagrant_openstack.timeout'))
          fail Errors::SshUnavailable, host: @resolver.resolve_floating_ip(env), timeout: ssh_timeout
        end

        def server_is_reachable?(env, timeout)
          start_time = Time.now
          current_time = start_time
          nb_retry = 0

          while (current_time - start_time) <= timeout
            @logger.debug "Checking if SSH port is open... Attempt number #{nb_retry}"
            if nb_retry % 5 == 0
              @logger.info 'Waiting for SSH to become available...'
              env[:ui].info(I18n.t('vagrant_openstack.waiting_for_ssh'))
            end

            env[:ssh_run_command] = 'exit 0'
            @ssh.call(env)
            return true  if env[:ssh_run_exit_status] == 0

            @logger.debug 'SSH not yet available... new retry in in 1 second'
            nb_retry += 1
            sleep 1
            current_time = Time.now
          end

          false
        end
      end
    end
  end
end
