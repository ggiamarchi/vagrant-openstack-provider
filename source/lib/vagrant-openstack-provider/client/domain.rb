require 'log4r'
require 'restclient'
require 'json'

module VagrantPlugins
  module Openstack
    module Domain
      class Item
        attr_accessor :id, :name
        def initialize(id, name)
          @id = id
          @name = name
        end
      end

      class FloatingIP
        attr_accessor :ip, :pool, :instance_id
        def initialize(ip, pool, instance_id)
          @ip = ip
          @pool = pool
          @instance_id = instance_id
        end
      end
    end
  end
end
