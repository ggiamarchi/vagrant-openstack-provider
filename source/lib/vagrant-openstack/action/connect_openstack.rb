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
          @app = app
          @logger = Log4r::Logger.new("vagrant_openstack::action::connect_openstack")
        end

        def call(env)
          # Get the configs
          config = env[:machine].provider_config
          api_key = config.api_key
          username = config.username
          openstack_auth_url = config.openstack_auth_url
          tenant_name = config.tenant_name

          params = {
              :provider => :openstack,
              #:version  => :v2, # TODO
              :openstack_tenant => tenant_name,
              :openstack_api_key => api_key,
              :openstack_username => username,
              :openstack_auth_url => openstack_auth_url
          }

          if config.network
            env[:openstack_network] = Fog::Network.new({
                                                           :provider => :openstack,
                                                           :openstack_username => username,
                                                           :openstack_api_key => api_key,
                                                           :openstack_auth_url => openstack_auth_url
                                                       })
          end

          env[:openstack_compute] = Fog::Compute.new params

          @app.call(env)
        end
      end
    end
  end
end
