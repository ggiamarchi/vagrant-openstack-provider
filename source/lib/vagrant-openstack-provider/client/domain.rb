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

      class Flavor < Item
        #
        # THe number of vCPU
        #
        attr_accessor :vcpus

        #
        # The amount of RAM in Megaoctet
        #
        attr_accessor :ram

        #
        # The size of root disk in Gigaoctet
        #
        attr_accessor :disk

        def initialize(id, name, vcpus, ram, disk)
          @vcpus = vcpus
          @ram  = ram
          @disk = disk
          super(id, name)
        end

        def ==(other)
          other.class == self.class && other.state == state
        end

        protected

        def state
          [@id, @name, @vcpus, @ram, @disk]
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
