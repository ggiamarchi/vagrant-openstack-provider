require "log4r"
require "restclient"
require "json"
require_relative "../openstack_client"

module VagrantPlugins
  module Openstack
    module Action
      # This action connects to Openstack, verifies credentials work, and
      # puts the Openstack connection object into the `:openstack_compute` key
      # in the environment.
      class ConnectOpenstack
        def initialize(app, _env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_openstack::action::connect_openstack")
        end

        def call(env)
          # Get the configs
          client = OpenstackClient.new
          env[:openstack_client] = client
          client.authenticate(env)
          @app.call(env)
        end
      end
    end
  end
end
