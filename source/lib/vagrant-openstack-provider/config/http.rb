module VagrantPlugins
  module Openstack
    class HttpConfig
      UNSET_VALUE = Vagrant.plugin('2', :config).const_get(:UNSET_VALUE)

      #
      # @return [Integer]
      attr_accessor :open_timeout

      #
      # @return [Integer]
      attr_accessor :read_timeout

      #
      # @return [Integer]
      attr_accessor :proxy

      def initialize
        @open_timeout = UNSET_VALUE
        @read_timeout = UNSET_VALUE
        @proxy = UNSET_VALUE
      end

      def finalize!
        @open_timeout = 60 if @open_timeout == UNSET_VALUE
        @read_timeout = 30 if @read_timeout == UNSET_VALUE
        @proxy = nil if @proxy == UNSET_VALUE
      end

      def merge(other)
        result = self.class.new

        [self, other].each do |obj|
          obj.instance_variables.each do |key|
            next if key.to_s.start_with?('@__')

            value = obj.instance_variable_get(key)
            result.instance_variable_set(key, value) if value != UNSET_VALUE
          end
        end
        result
      end
    end
  end
end
