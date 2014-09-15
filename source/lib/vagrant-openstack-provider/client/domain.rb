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

        def ==(other)
          other.class == self.class && other.state == state
        end

        def state
          [@id, @name]
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

      class Volume < Item
        #
        # Size in Gigaoctet
        #
        attr_accessor :size

        #
        # Status (e.g. 'Available', 'In-use')
        #
        attr_accessor :status

        #
        # Whether volume is bootable or not
        #
        attr_accessor :bootable

        #
        # instance id volume is attached to
        #
        attr_accessor :instance_id

        #
        # device (e.g. /dev/sdb) if attached
        #
        attr_accessor :device

        # rubocop:disable Style/ParameterLists
        def initialize(id, name, size, status, bootable, instance_id, device)
          @size = size
          @status = status
          @bootable = bootable
          @instance_id = instance_id
          @device = device
          super(id, name)
        end
        # rubocop:enable Style/ParameterLists

        def to_s
          {
            id: @id,
            name: @name,
            size: @size,
            status: @status,
            bootable: @bootable,
            instance_id: @instance_id,
            device: @device
          }.to_json
        end

        protected

        def state
          [@id, @name, @size, @status, @bootable, @instance_id, @device]
        end
      end
    end
  end
end
