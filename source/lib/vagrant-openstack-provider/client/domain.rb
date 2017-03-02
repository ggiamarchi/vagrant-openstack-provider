require 'log4r'
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

      class Image < Item
        attr_accessor :visibility
        attr_accessor :size
        attr_accessor :min_ram
        attr_accessor :min_disk
        attr_accessor :metadata

        # rubocop:disable Metrics/ParameterLists
        def initialize(id, name, visibility = nil, size = nil, min_ram = nil, min_disk = nil, metadata = {})
          @visibility = visibility
          @size = size
          @min_ram = min_ram
          @min_disk = min_disk
          @metadata = metadata
          super(id, name)
        end
        # rubocop:enable Metrics/ParameterLists

        protected

        def state
          [@id, @name, @visibility, @size, @min_ram, @min_disk, @metadata]
        end
      end

      class Flavor < Item
        #
        # The number of vCPU
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

        # rubocop:disable Metrics/ParameterLists
        def initialize(id, name, size, status, bootable, instance_id, device)
          @size = size
          @status = status
          @bootable = bootable
          @instance_id = instance_id
          @device = device
          super(id, name)
        end
        # rubocop:enable Metrics/ParameterLists

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

      class Subnet < Item
        attr_accessor :cidr
        attr_accessor :enable_dhcp
        attr_accessor :network_id

        def initialize(id, name, cidr, enable_dhcp, network_id)
          @cidr = cidr
          @enable_dhcp = enable_dhcp
          @network_id = network_id
          super(id, name)
        end

        protected

        def state
          [@id, @name, @cidr, @enable_dhcp, @network_id]
        end
      end
    end
  end
end
