require "fog"
require "log4r"

require 'vagrant/util/retryable'

module VagrantPlugins
  module Rackspace
    module Action
      # This creates the Rackspace server.
      class CreateServer
        include Vagrant::Util::Retryable

        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_rackspace::action::create_server")
        end

        def call(env)
          # Get the configs
          config   = env[:machine].provider_config

          # Find the flavor
          env[:ui].info(I18n.t("vagrant_rackspace.finding_flavor"))
          flavor = find_matching(env[:rackspace_compute].flavors.all, config.flavor)
          raise Errors::NoMatchingFlavor if !flavor

          # Find the image
          env[:ui].info(I18n.t("vagrant_rackspace.finding_image"))
          image = find_matching(env[:rackspace_compute].images.all, config.image)
          raise Errors::NoMatchingImage if !image

          # Figure out the name for the server
          server_name = config.server_name || env[:machine].name

          # If we're using the default keypair, then show a warning
          default_key_path = Vagrant.source_root.join("keys/vagrant.pub").to_s
          public_key_path  = File.expand_path(config.public_key_path, env[:root_path])

          if default_key_path == public_key_path
            env[:ui].warn(I18n.t("vagrant_rackspace.warn_insecure_ssh"))
          end

          # Output the settings we're going to use to the user
          env[:ui].info(I18n.t("vagrant_rackspace.launching_server"))
          env[:ui].info(" -- Flavor: #{flavor.name}")
          env[:ui].info(" -- Image: #{image.name}")
          env[:ui].info(" -- Disk Config: #{config.disk_config}") if config.disk_config
          env[:ui].info(" -- Name: #{server_name}")

          # Build the options for launching...
          options = {
            :flavor_id   => flavor.id,
            :image_id    => image.id,
            :name        => server_name,
            :personality => [
              {
                :path     => "/root/.ssh/authorized_keys",
                :contents => Base64.encode64(File.read(public_key_path))
              }
            ]
          }
          options[:disk_config] = config.disk_config if config.disk_config

          # Create the server
          server = env[:rackspace_compute].servers.create(options)

          # Store the ID right away so we can track it
          env[:machine].id = server.id

          # Wait for the server to finish building
          env[:ui].info(I18n.t("vagrant_rackspace.waiting_for_build"))
          retryable(:on => Fog::Errors::TimeoutError, :tries => 200) do
            # If we're interrupted don't worry about waiting
            next if env[:interrupted]

            # Set the progress
            env[:ui].clear_line
            env[:ui].report_progress(server.progress, 100, false)

            # Wait for the server to be ready
            begin
              server.wait_for(5) { ready? }
            rescue RuntimeError => e
              # If we don't have an error about a state transition, then
              # we just move on.
              raise if e.message !~ /should have transitioned/
              raise Errors::CreateBadState, :state => server.state
            end
          end

          if !env[:interrupted]
            # Clear the line one more time so the progress is removed
            env[:ui].clear_line

            # Wait for RackConnect to complete
            if ( config.rackconnect )
              env[:ui].info(I18n.t("vagrant_rackspace.waiting_for_rackconnect"))
              while true
                status = server.metadata.all["rackconnect_automation_status"]
                if ( !status.nil? )
                  env[:ui].info( status )
                end
                break if env[:interrupted]
                break if (status.to_s =~ /deployed/i)
                sleep 10
              end
            end

            # Wait for SSH to become available
            env[:ui].info(I18n.t("vagrant_rackspace.waiting_for_ssh"))
            while true
              # If we're interrupted then just back out
              break if env[:interrupted]
              break if env[:machine].communicate.ready?
              sleep 2
            end

            env[:ui].info(I18n.t("vagrant_rackspace.ready"))
          end

          @app.call(env)
        end

        protected

        # This method finds a matching _thing_ in a collection of
        # _things_. This works matching if the ID or NAME equals to
        # `name`. Or, if `name` is a regexp, a partial match is chosen
        # as well.
        def find_matching(collection, name)
          collection.each do |single|
            return single if single.id == name
            return single if single.name == name
            return single if name.is_a?(Regexp) && name =~ single.name
          end

          nil
        end
      end
    end
  end
end
