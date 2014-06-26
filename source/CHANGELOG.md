# 0.2.0 (June 26, 2014)

FEATURES:

  - Enable "networks" configuration [#26](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/26)
  - Implement "suspend" action [#17](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/17)
  - Implement "resume" action [#16](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/16)
  - Implement "reload" action [#9](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/9)
  - Implement "halt" action [#8](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/8)

IMPROVEMENTS:

  - Add sync_method configuration parameter [#12](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/12)
  - Avoid multiple Openstack connection [#37](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/37)
  - Update appraisal configuration for vagrant 1.5 and 1.6 [#32](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/32)
  - In provider's configuration, rename "api_key" to "password" [#30](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/30)
  - Remove default value for "image" and "flavor" configuration parameter [10](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/10) [11](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/11)

BUG FIXES:

  - When a VM is shutoff, the plugin consider it is not created bug [#36](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/36)
  - Hardcoded network name in source code [#34](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/34)
  - Missing translations [#33](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/33)
  - Vagrant steal floating IP of another VM [#23](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/23)
  - Vagrant does not always knows the state of the machine [#21](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/21)
  - Fix "Waiting for ssh to be ready" in create_server [#2](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/2)

# 0.1.2 (April 25, 2014)

IMPROVEMENTS:

  - Rename everything from vagrant-openstack to vagrant-openstack-provider

# 0.1.1 (April 24, 2014)

BUG FIXES:

  - Remove fog dependencies

# 0.1 (April 24, 2014)

* Initial release.
