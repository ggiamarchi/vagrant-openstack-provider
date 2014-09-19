# 0.3.3 (September 19, 2014)

BUG FIXES:

   - Fix rest-client dependency error [#95](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/95)

# 0.3.2 (September 1, 2014)

BUG FIXES:

   - The provider fails to load colorize gem [#76](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/76)
   - Sub-command arguments management have change in vagrant 1.5 [#77](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/77)

IMPROVEMENTS:

   - Show more informations for command flavor-list [#52](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/52) 

# 0.3.0 (August 29, 2014)

FEATURES:

  - Automatic generation of SSH keys [#68](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/68)
  - Make keypair optional in provider's configuration [#54](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/54)
  - Allow setting a floating ip pool rather than a fixed ip [#50](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/50)
  - Implement custom "list" actions [#35](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/35)
  - Enable "availability_zone" configuration [#27](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/27)

IMPROVEMENTS:

  - Log action steps and client calls with requests and responses [#58](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/58)

BUG FIXES:

  - When`vagrant reload` an existing but stoped machine it does not start [#57](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/57)
  - When`vagrant up` an existing but stoped machine it does not start [#56](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/56)
  - Network api URL resolve from keystone catalog is not working [#49](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/49)

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
