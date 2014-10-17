---
layout: index
title: Quickstart
---


## <span class="glyphicon glyphicon-chevron-right"></span> Installation

First, you need Vagrant 1.4 or newer to be installed on you system. If you have
already install Vagrant, you can obtain a binary package from vagrantup.com

Then, the plugin has to be install using standard Vagrant 1.1+ plugin installation
methods.

<pre class="prettyprint lang-bash">
$ vagrant plugin install vagrant-openstack-provider
</pre>

## <span class="glyphicon glyphicon-chevron-right"></span> Simple Vagrantfile

<pre class="prettyprint">
Vagrant.configure('2') do |config|

  config.vm.box       = 'openstack'

  config.ssh.username = 'stack'

  config.vm.provider :openstack do |os|
    os.openstack_auth_url = 'http://keystone-server.net/v2.0/tokens'
    os.username           = 'openstackUser'
    os.password           = 'openstackPassword'
    os.tenant_name        = 'myTenant'
    os.flavor             = 'm1.small'
    os.image              = 'ubuntu'
    os.floating_ip_pool   = 'publicNetwork'
  end
end
</pre>

<pre class="prettyprint lang-bash">
$ vagrant up --provider=openstack
</pre>
