# 0.5.0 (November 4, 2014)

FEATURES:

  - Add an option to disable SSH Authentication and allow private vms [#120](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/120)
  - Support for fixed IP address for private network [#87](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/87)

IMPROVEMENTS:

  - Accept a string for ssh_timeout value [#144](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/144)
  - Vagrant Openstack should works in degraded mode id only Keystone and Nova are availables [#142](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/142)
  - Add custom command `vagrant openstack reset [#107](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/107)
  - Make box optional [#105](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/105)
  - vagrant up => Instance could not be found [#98](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/98)

BUG FIXES:

  - security_groups should be an array of hashes [#137](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/137)
  - user_data needs to be Base64 encoded in Nova.createServer [#122](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/122)
  - SSH failures after port 22 is open because user doesn't exist yet [#106](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/106)
  - Floating IP should not be mandatory [#55](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/55)
  - sync_folders error under windows 7 [#119](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/119)
  - Ansible provisionner doesn't use our generated SSH key [#133](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/133)

# 0.4.1 (October 3, 2014)

BUG FIXES:

  - initialize': must pass :url (ArgumentError) when neutron url is not present [#112](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/112)

# 0.4.0 (September 23, 2014)

FEATURES:

  - Enable "metadata" in config for nova create server [#25](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/25)
  - Enable "user_data" in config for nova create server [#78](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/78)
  - Enable "security_groups" in config for nova create server [#82](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/82)
  - Enable "scheduler_hints" in config for nova create server [#83](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/83)
  - Allow attaching an existing volume to the vagrant instance [#24](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/24)
  - Allow booting instance from volume [#44](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/44)
  - Add subcommand volume-list [#75](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/75)

IMPROVEMENTS:

  - Add config param floating_ip_pool_always_allocate [#61](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/61)

BUG FIXES:

  - Enable config option to override SSH port [#88](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/88)


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
