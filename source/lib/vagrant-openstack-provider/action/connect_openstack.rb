require 'log4r'
require 'restclient'
require 'json'

require 'vagrant-openstack-provider/client/openstack'

module VagrantPlugins
  module Openstack
    module Action
      class ConnectOpenstack
        def initialize(app, _env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_openstack::action::connect_openstack')
        end

        def call(env)
          client = VagrantPlugins::Openstack
          env[:openstack_client] = client
          client.keystone.authenticate(env) if client.session.token.nil?
          @app.call(env)
        end
      end
    end
  end
end
