require 'log4r'
require 'restclient'
require 'json'

require 'vagrant-openstack-provider/client/keystone'

module VagrantPlugins
  module Openstack
    module Utils
      def handle_response(response)
        case response.code
        when 200, 201, 202, 204
          response
        when 401
          fail Errors::AuthenticationRequired
        when 400
          fail Errors::VagrantOpenstackError, message: JSON.parse(response.to_s)['badRequest']['message']
        else
          fail Errors::VagrantOpenstackError, message: response.to_s
        end
      end

      def authenticated(env)
        nb_retry = 0
        begin
          return yield
        rescue Errors::AuthenticationRequired => e
          nb_retry += 1
          env[:ui].warn(e)
          env[:ui].warn(I18n.t('vagrant_openstack.trying_authentication'))
          env[:openstack_client].keystone.authenticate(env)
          retry if nb_retry < 3
          raise e
        end
      end

      class Item
        attr_accessor :id, :name
        def initialize(id, name)
          @id = id
          @name = name
        end
      end
    end
  end
end
