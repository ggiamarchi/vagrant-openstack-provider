require 'log4r'
require 'json'

require 'vagrant-openstack-provider/client/openstack'
require 'vagrant-openstack-provider/client/request_logger'
require 'vagrant-openstack-provider/action/abstract_action'
require 'vagrant-openstack-provider/catalog/openstack_catalog'

module VagrantPlugins
  module Openstack
    module Action
      class ConnectOpenstack < AbstractAction
        include VagrantPlugins::Openstack::HttpUtils::RequestLogger
        include VagrantPlugins::Openstack::Catalog

        def initialize(app, env, catalog_reader = OpenstackCatalog.new)
          @app = app
          @logger = Log4r::Logger.new('vagrant_openstack::action::connect_openstack')
          @catalog_reader = catalog_reader
          env[:openstack_client] = VagrantPlugins::Openstack
        end

        def execute(env)
          client = env[:openstack_client]
          if client.session.token.nil?
            catalog = client.keystone.authenticate(env)
            @catalog_reader.read(env, catalog)
            override_endpoint_catalog_with_user_config(env)
            check_configuration(env)
            log_endpoint_catalog(env)
          end
          @app.call(env) unless @app.nil?
        end

        private

        def override_endpoint_catalog_with_user_config(env)
          client = env[:openstack_client]
          config = env[:machine].provider_config
          endpoints = client.session.endpoints
          endpoints[:compute] = config.openstack_compute_url unless config.openstack_compute_url.nil?
          endpoints[:network] = config.openstack_network_url unless config.openstack_network_url.nil?
          endpoints[:volume]  = config.openstack_volume_url  unless config.openstack_volume_url.nil?
          endpoints[:image]   = config.openstack_image_url   unless config.openstack_image_url.nil?
          endpoints.delete_if { |_, value| value.nil? || value.empty? }
        end

        def check_configuration(env)
          fail Errors::MissingNovaEndpoint unless env[:openstack_client].session.endpoints.key? :compute
        end

        def log_endpoint_catalog(env)
          env[:openstack_client].session.endpoints.each do |key, value|
            @logger.info(" -- #{key.to_s.ljust 15}: #{value}")
          end
        end
      end
    end
  end
end
