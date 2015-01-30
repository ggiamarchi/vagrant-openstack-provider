require 'log4r'
require 'json'

module VagrantPlugins
  module Openstack
    module HttpUtils
      module RequestLogger
        def log_request(method, url, body = nil, headers)
          @logger.debug "request  => method  : #{method}"
          @logger.debug "request  => url     : #{url}"
          @logger.debug "request  => headers : #{headers}"
          @logger.debug "request  => body    : #{body}" unless body.nil?
        end

        def log_response(response)
          @logger.debug "response => code    : #{response.code}"
          @logger.debug "response => headers : #{response.headers}"
          @logger.debug "response => body    : #{response}"
        end
      end
    end
  end
end
