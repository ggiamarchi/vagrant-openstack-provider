require "fog"
require "log4r"

module VagrantPlugins
  module Openstack
    module Action
      # This action connects to Openstack, verifies credentials work, and
      # puts the Openstack connection object into the `:openstack_compute` key
      # in the environment.
      class ConnectOpenstack
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_openstack::action::connect_openstack")
        end

        def call(env)
          # Get the configs
          config   = env[:machine].provider_config
          api_key  = config.api_key
          username = config.username

          params = {
            :provider => :openstack,
            :version  => :v2,
            :openstack_api_key => api_key,
            :openstack_username => username,
            :openstack_auth_url => config.openstack_auth_url
          }

          if config.openstack_compute_url
            @logger.info("Connecting to Openstack compute_url...")
            params[:openstack_compute_url] = config.openstack_compute_url
          else
            @logger.info("Connecting to Openstack region...")
            params[:openstack_region] = config.openstack_region
          end

          env[:openstack_compute] = Fog::Compute.new params

          @app.call(env)
        end
      end
    end
  end
end
