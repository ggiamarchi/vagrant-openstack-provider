module VagrantPlugins
  module Openstack
    #
    # Stable versions must respect the pattern given
    # by VagrantPlugins::Openstack::VERSION_PATTERN
    #
    VERSION = '0.12.0'

    #
    # Stable version must respect the naming convention 'x.y.z'
    # where x, y and z are integers inside the range [0, 999]
    #
    VERSION_PATTERN = /^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$/
  end
end
