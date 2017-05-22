require 'restclient'

module VagrantPlugins
  module Openstack
    module RestUtils
      def self.get(env, url, headers = {}, &block)
        config = env[:machine].provider_config
        RestClient::Request.execute(method: :get, url: url, headers: headers,
                                    timeout: config.http.read_timeout, open_timeout: config.http.open_timeout,
                                    ssl_ca_file: config.ssl_ca_file, verify_ssl: config.ssl_verify_peer, &block)
      end

      def self.post(env, url, payload, headers = {}, &block)
        config = env[:machine].provider_config
        RestClient::Request.execute(method: :post, url: url, payload: payload, headers: headers,
                                    timeout: config.http.read_timeout, open_timeout: config.http.open_timeout,
                                    ssl_ca_file: config.ssl_ca_file, verify_ssl: config.ssl_verify_peer, &block)
      end

      def self.delete(env, url, headers = {}, &block)
        config = env[:machine].provider_config
        RestClient::Request.execute(method: :delete, url: url, headers: headers,
                                    timeout: config.http.read_timeout, open_timeout: config.http.open_timeout,
                                    ssl_ca_file: config.ssl_ca_file, verify_ssl: config.ssl_verify_peer, &block)
      end
    end
  end
end
