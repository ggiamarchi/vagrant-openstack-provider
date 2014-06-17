require "log4r"
require 'socket'
require "timeout"

require 'vagrant/util/retryable'

module VagrantPlugins
  module Openstack
    module Action
      class CreateServer
        include Vagrant::Util::Retryable

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_openstack::action::create_server")
        end

        def call(env)
          config = env[:machine].provider_config
          client = env[:openstack_client]

          # Find the flavor
          env[:ui].info(I18n.t("vagrant_openstack.finding_flavor"))
          flavors = client.get_all_flavors(env)
          flavor = find_matching(flavors, config.flavor)
          raise Errors::NoMatchingFlavor if !flavor

          # Find the image
          env[:ui].info(I18n.t("vagrant_openstack.finding_image"))
          images = client.get_all_images(env)
          image = find_matching(images, config.image)
          raise Errors::NoMatchingImage if !image

          # Figure out the name for the server
          server_name = config.server_name || env[:machine].name

          # Output the settings we're going to use to the user
          env[:ui].info(I18n.t("vagrant_openstack.launching_server"))
          env[:ui].info(" -- Flavor       : #{flavor.name}")
          env[:ui].info(" -- FlavorRef    : #{flavor.id}")
          env[:ui].info(" -- Image        : #{image.name}")
          env[:ui].info(" -- KeyPair      : #{config.keypair_name}")
          env[:ui].info(" -- ImageRef     : #{image.id}")
          env[:ui].info(" -- Tenant       : #{config.tenant_name}")
          env[:ui].info(" -- Name         : #{server_name}")

          server_id = client.create_server(env, server_name, image.id, flavor.id, config.keypair_name)

          # Store the ID right away so we can track it
          env[:machine].id = server_id

          # Wait for the server to finish building
          env[:ui].info(I18n.t("vagrant_openstack.waiting_for_build"))
          timeout(200) do
            while client.get_server_details(env, server_id)['status'] != 'ACTIVE' do
              sleep 3
              @logger.debug("Waiting for server to be ACTIVE")
            end
          end

          if config.floating_ip
            env[:ui].info("Using floating IP #{config.floating_ip}")
            client.add_floating_ip(env, server_id, config.floating_ip)
          end

          if !env[:interrupted]
            # Clear the line one more time so the progress is removed
            env[:ui].clear_line

            # Wait for SSH to become available
            host = env[:machine].provider_config.floating_ip
            ssh_timeout = env[:machine].provider_config.ssh_timeout
            if !port_open?(env, host, 22, ssh_timeout)
              env[:ui].error(I18n.t("vagrant_openstack.timeout"))
              raise Errors::SshUnavailable,
                    :host    => host,
                    :timeout => ssh_timeout
            end

            env[:ui].info(I18n.t("vagrant_openstack.ready"))
          end

          @app.call(env)
        end

        protected

        def port_open?(env, ip, port, timeout)
          start_time = Time.now
          current_time = start_time
          while (current_time - start_time) <= timeout
            begin
              env[:ui].info(I18n.t("vagrant_openstack.waiting_for_ssh"))
              TCPSocket.new(ip, port)
              return true
            rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ETIMEDOUT
              sleep 1
            end
            current_time = Time.now
          end
          return false
        end

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
