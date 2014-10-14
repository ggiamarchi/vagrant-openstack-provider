require 'log4r'
require 'rbconfig'
require 'vagrant/util/subprocess'

module VagrantPlugins
  module Openstack
    module Action
      class SyncFolders
        def initialize(app, _env)
          @app = app
        end

        def call(env)
          sync_method = env[:machine].provider_config.sync_method
          ssh_disabled = env[:machine].provider_config.ssh_disabled
          if sync_method == 'none' || ssh_disabled
            NoSyncFolders.new(@app, env, ssh_disabled).call(env)
          elsif sync_method == 'rsync'
            RsyncFolders.new(@app, env).call(env)
          else
            fail Errors::SyncMethodError, sync_method_value: sync_method
          end
        end
      end

      class NoSyncFolders
        def initialize(app, _env, ssh_disabled)
          @app = app
          @ssh_disabled = ssh_disabled
        end

        def call(env)
          @app.call(env)
          env[:ui].info('Folders will not be synced because provider config ssh_disabled is set to true') if @ssh_disabled
          env[:ui].info('Sync folders are disabled in the provider configuration') unless @ssh_disabled
        end
      end

      # This middleware uses `rsync` to sync the folders over to the
      # remote instance.
      class RsyncFolders
        def initialize(app, _env)
          @app    = app
          @logger = Log4r::Logger.new('vagrant_openstack::action::sync_folders')
          @host_os = RbConfig::CONFIG['host_os']
        end

        def call(env)
          @app.call(env)

          ssh_info = env[:machine].ssh_info

          config          = env[:machine].provider_config
          rsync_includes  = config.rsync_includes.to_a

          env[:machine].config.vm.synced_folders.each do |_, data|
            hostpath  = File.expand_path(data[:hostpath], env[:root_path])
            guestpath = data[:guestpath]

            # Make sure there is a trailing slash on the host path to
            # avoid creating an additional directory with rsync
            hostpath = "#{hostpath}/" if hostpath !~ /\/$/

            # If on Windows, modify the path to work with cygwin rsync
            if @host_os =~ /mswin|mingw|cygwin/
              hostpath = add_cygdrive_prefix_to_path(hostpath)
            end

            env[:ui].info(I18n.t('vagrant_openstack.rsync_folder', hostpath: hostpath, guestpath: guestpath))

            # Create the guest path
            env[:machine].communicate.sudo("mkdir -p '#{guestpath}'")
            env[:machine].communicate.sudo(
              "chown -R #{ssh_info[:username]} '#{guestpath}'")

            # Generate rsync include commands
            includes = rsync_includes.each_with_object([]) do |incl, incls|
              incls << '--include'
              incls << incl
            end

            # Rsync over to the guest path using the SSH info. add
            # .hg/ and .git/ to exclude list as that isn't covered in
            # --cvs-exclude
            command = [
              'rsync', '--verbose', '--archive', '-z',
              '--cvs-exclude',
              '--exclude', '.hg/',
              '--exclude', '.git/',
              '--chmod', 'ugo=rwX',
              *includes,
              '-e', "ssh -p #{ssh_info[:port]} -o StrictHostKeyChecking=no #{ssh_key_options(ssh_info)}",
              hostpath,
              "#{ssh_info[:username]}@#{ssh_info[:host]}:#{guestpath}"]
            command.compact!

            # during rsync, ignore files specified in .hgignore and
            # .gitignore traditional .gitignore or .hgignore files
            ignore_files = ['.hgignore', '.gitignore']
            ignore_files.each do |ignore_file|
              abs_ignore_file = env[:root_path].to_s + '/' + ignore_file
              command += ['--exclude-from', abs_ignore_file] if File.exist?(abs_ignore_file)
            end

            r = Vagrant::Util::Subprocess.execute(*command)
            next if r.exit_code == 0
            fail Errors::RsyncError, guestpath: guestpath, hostpath: hostpath, stderr: r.stderr
          end
        end

        private

        def ssh_key_options(ssh_info)
          # Ensure that `private_key_path` is an Array (for Vagrant < 1.4)
          Array(ssh_info[:private_key_path]).map { |path| "-i '#{path}' " }.join
        end

        def add_cygdrive_prefix_to_path(hostpath)
          hostpath.downcase.sub(/^([a-z]):\//) do
            "/cygdrive/#{Regexp.last_match[1]}/"
          end
        end
      end
    end
  end
end
