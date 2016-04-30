# 0.7.2 (May 1, 2016)

IMPROVEMENTS:

  - Allow status and ssh to run without a lock #282
  - Switch to standard WaitForCommunicator middleware #281

BUG FIXES:

  - Run provisioner cleanup when destroying VMs #272
  - Windows host provisioning using Winrm #264
  - Use only provided ssh key and don't touch the known_hosts #259
  - Fix hooks for provisioners #248, #249, #28
  - Support standard option config.vm.boot_timeout #227

# 0.7.1 (February 19, 2016)

BUG FIXES:

  - Fix dependency to make it work with Vagrant 1.8 #265, #266 , #268
  - Fix heat stack create when multiple machines are declared #260
  - Fix regression, vagrant provision was broken #240

# 0.7.0 (August 10, 2015)
  
FEATURES:

  - Access to obtained floating IP from provisioner phase [#205](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/205) 

IMPROVEMENTS:

  - Autodetect new version of the provider and provide info message to update [#132](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/132)
  - Documentation for the `ssh_timeout` option [#230](https://github.com/ggiamarchi/vagrant-openstack-provider/pull/230) 

BUG FIXES:

  - scheduler_hints ignored due to incorrect json tag in create request [#231](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/231) 
  - delete_keypair_if_vagrant throws exception if key_name is missing [#238](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/238) 
  - Fix Vagrant 1.4 bug, extra_data attr not found [#211](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/211) 
  - Add suffix /tokens in auth url if missing [#208](https://github.com/ggiamarchi/vagrant-openstack-provider/pull/208) 

# 0.6.1 (January 30, 2015)

IMPROVEMENTS:

  - Straightforward syntax to define single networks [#193](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/193)
  - Network preference for SSH [#194](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/194)
  - Allow lists in flavor values [#189](https://github.com/ggiamarchi/vagrant-openstack-provider/pull/189)
  - Allow "wait active" timeout to be configurable [#185](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/185)
  - Allow setting timeout value for REST calls [#183](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/183)

BUG FIXES:

  - Vagrant openstack reset fails when the instance is not found [#195](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/195)
  - Show explicit error when tenant is missing in credentials [#186](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/186)

# 0.6.0 (November 28, 2014)

FEATURES:

  - First implementation of Heat Stacks [#170](https://github.com/ggiamarchi/vagrant-openstack-provider/pull/170)
  - Allow public and private networks to be specified [#148](https://github.com/ggiamarchi/vagrant-openstack-provider/pull/148)
  - Add custom command "subnet-list" [#160](https://github.com/ggiamarchi/vagrant-openstack-provider/pull/160)
  - Allow public and private networks to be specified [#148](https://github.com/ggiamarchi/vagrant-openstack-provider/pull/148)
  - Add config parameter os.region [#128](https://github.com/ggiamarchi/vagrant-openstack-provider/pull/128)

IMPROVEMENTS:

  - Rsync all files [#166](https://github.com/ggiamarchi/vagrant-openstack-provider/pull/166)
  - Support glance API v1 [#168](https://github.com/ggiamarchi/vagrant-openstack-provider/pull/168)
  - Replace fail <string> by fail Errors::... [#152](https://github.com/ggiamarchi/vagrant-openstack-provider/pull/152)
  - When an unknown error occurs, provide information to debug and submit issue [#115](https://github.com/ggiamarchi/vagrant-openstack-provider/pull/115)
  - Print more information for command "vagrant openstack image-list" [#104](https://github.com/ggiamarchi/vagrant-openstack-provider/pull/104)
  - Cannot 'resume' while instance is in vm_state active [#91](https://github.com/ggiamarchi/vagrant-openstack-provider/pull/91)
  - Allow config.floating_ip_pool to take an array as input [#90](https://github.com/ggiamarchi/vagrant-openstack-provider/pull/90)
  - Display the current task value in the status option [#89](https://github.com/ggiamarchi/vagrant-openstack-provider/pull/89)

BUG FIXES:

  - Fix ssh_disabled [#182](https://github.com/ggiamarchi/vagrant-openstack-provider/pull/182)
  - Avoid printing contribution message on user interruption [#169](https://github.com/ggiamarchi/vagrant-openstack-provider/pull/169)
  - Network configuration is lost when machine definition overrides provider's configuration [#146](https://github.com/ggiamarchi/vagrant-openstack-provider/pull/146)
  - When VM status is "ERROR" continue waiting for startup [#62](https://github.com/ggiamarchi/vagrant-openstack-provider/pull/62)

DOCUMENTATION:

  - Add a CONTRIBUTING.md file [#151](https://github.com/ggiamarchi/vagrant-openstack-provider/pull/151)

# 0.5.2 (November 6, 2014)

BUG FIXES:

  - When multiple IPs are available, return the first one instead of failing [#155](https://github.com/ggiamarchi/vagrant-openstack-provider/pull/155)


# 0.5.1 (November 6, 2014)

BUG FIXES:

  - Allow public and private networks to be specified [#148](https://github.com/ggiamarchi/vagrant-openstack-provider/pull/148)

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
