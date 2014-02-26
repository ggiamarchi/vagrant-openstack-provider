require "log4r"
require 'rbconfig'
require "vagrant/util/subprocess"

module VagrantPlugins
  module Openstack
    module Action
      # This middleware uses `rsync` to sync the folders over to the
      # remote instance.
      class SyncFolders
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_openstack::action::sync_folders")
          @host_os = RbConfig::CONFIG['host_os']
        end

        def call(env)
          @app.call(env)

          ssh_info = env[:machine].ssh_info

          config          = env[:machine].provider_config
          rsync_includes  = config.rsync_includes.to_a

          env[:machine].config.vm.synced_folders.each do |id, data|
            hostpath  = File.expand_path(data[:hostpath], env[:root_path])
            guestpath = data[:guestpath]

            # Make sure there is a trailing slash on the host path to
            # avoid creating an additional directory with rsync
            hostpath = "#{hostpath}/" if hostpath !~ /\/$/
            
            # If on Windows, modify the path to work with cygwin rsync
            if @host_os =~ /mswin|mingw|cygwin/
              hostpath = hostpath.sub(/^([A-Za-z]):\//, "/cygdrive/#{$1.downcase}/")
            end

            env[:ui].info(I18n.t("vagrant_openstack.rsync_folder",
                                :hostpath => hostpath,
                                :guestpath => guestpath))

            # Create the guest path
            env[:machine].communicate.sudo("mkdir -p '#{guestpath}'")
            env[:machine].communicate.sudo(
              "chown -R #{ssh_info[:username]} '#{guestpath}'")

            # Generate rsync include commands
            includes = rsync_includes.each_with_object([]) { |incl, incls| 
              incls << "--include" 
              incls << incl
            }

            # Rsync over to the guest path using the SSH info. add
            # .hg/ to exclude list as that isn't covered in
            # --cvs-exclude
            command = [
              "rsync", "--verbose", "--archive", "-z",
              "--cvs-exclude", 
              "--exclude", ".hg/",
              *includes,
              "-e", "ssh -p #{ssh_info[:port]} -o StrictHostKeyChecking=no #{ssh_key_options(ssh_info)}",
              hostpath,
              "#{ssh_info[:username]}@#{ssh_info[:host]}:#{guestpath}"]
            command.compact!

            # during rsync, ignore files specified in .hgignore and
            # .gitignore traditional .gitignore or .hgignore files
            ignore_files = [".hgignore", ".gitignore"]
            ignore_files.each do |ignore_file|
              abs_ignore_file = env[:root_path].to_s + "/" + ignore_file
              if File.exist?(abs_ignore_file)
                command = command + ["--exclude-from", abs_ignore_file]
              end
            end

            r = Vagrant::Util::Subprocess.execute(*command)
            if r.exit_code != 0
              raise Errors::RsyncError,
                :guestpath => guestpath,
                :hostpath => hostpath,
                :stderr => r.stderr
            end
          end
        end

        private
 
        def ssh_key_options(ssh_info)
          # Ensure that `private_key_path` is an Array (for Vagrant < 1.4)
          Array(ssh_info[:private_key_path]).map { |path| "-i '#{path}' " }.join
        end
      end
    end
  end
end
