# Vagrant OpenStack Cloud Provider

[![Build Status](https://api.travis-ci.org/ggiamarchi/vagrant-openstack-provider.png?branch=master)](https://travis-ci.org/ggiamarchi/vagrant-openstack-provider)
[![Gem Version](https://badge.fury.io/rb/vagrant-openstack-provider.svg)](http://badge.fury.io/rb/vagrant-openstack-provider)
[![Code Climate](https://codeclimate.com/github/ggiamarchi/vagrant-openstack-provider.png)](https://codeclimate.com/github/ggiamarchi/vagrant-openstack-provider)
[![Coverage Status](https://coveralls.io/repos/ggiamarchi/vagrant-openstack-provider/badge.png?branch=master)](https://coveralls.io/r/ggiamarchi/vagrant-openstack-provider?branch=master)

This is a [Vagrant](http://www.vagrantup.com) 1.6+ plugin that adds an
[OpenStack Cloud](http://www.openstack.org/software/) provider to Vagrant,
allowing Vagrant to control and provision machines within OpenStack
cloud.

**Note:** This plugin was originally forked from [mitchellh/vagrant-rackspace](https://github.com/mitchellh/vagrant-rackspace)

## Features

* Create and boot OpenStack instances
* Halt and reboot instances
* Suspend and resume instances
* SSH into the instances
* Automatic SSH key generation and Nova public key provisioning
* Automatic floating IP allocation and association
* Provision the instances with any built-in Vagrant provisioner
* Boot instance from volume
* Attach Cinder volumes to the instances
* Create and delete Heat Orchestration stacks
* Support OpenStack regions
* Custom sub-commands within Vagrant CLI to query OpenStack objects

## Usage

Install using standard Vagrant 1.1+ plugin installation methods. After
installing, `vagrant up` and specify the `openstack` provider. An example is
shown below.

```console
$ vagrant plugin install vagrant-openstack-provider
...
$ vagrant up
...
```

Make sure you have a recent version of vagrant (>1.7.1).

## Quick Start

After installing the plugin (instructions above), the quickest way to get
started is to specify all the details manually within a `config.vm.provider`
block in the Vagrantfile

Create a Vagrantfile that looks like the following, filling in your information
where necessary.

This Vagrantfile shows the minimal needed configuration.

```ruby
require 'vagrant-openstack-provider'

Vagrant.configure('2') do |config|

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
```

And then run `vagrant up`.

__NB.__
> See more examples in the [samples](https://github.com/ggiamarchi/vagrant-openstack-provider/tree/master/samples) directory.


## Configuration reference

This provider exposes quite a few provider-specific configuration options:

### Credentials

* `username` - The username with which to access OpenStack.
* `password` - The API key for accessing OpenStack.
* `domain_name` - The domain name when using identity API version 3 of keystone (Overrides user and project domain)
* `user_domain_name` - The OpenStack user domain name when using identity API version 3 of keystone
* `tenant_name` - The OpenStack project name to work on
* `project_name` - The OpenStack project name used in identity v3
* `project_domain_name` - The OpenStack project domain name used in identity v3
* `identity_api_version` - The identity version to use : 2 or 3. If not provided, vagrant will use 2 by default.
* `region` - The OpenStack region to work on
* `openstack_auth_url` - The endpoint to authenticate against.
* `openstack_compute_url` - The compute service URL to hit. This is good for custom endpoints. If not provided, vagrant will try to get it from catalog endpoint.
* `openstack_network_url` - The network service URL to hit. This is good for custom endpoints. If not provided, vagrant will try to get it from catalog endpoint.
* `openstack_volume_url` - The block storage URL to hit. This is good for custom endpoints. If not provided, vagrant will try to get it from catalog endpoint.
* `openstack_image_url` - The image URL to hit. This is good for custom endpoints. If not provided, vagrant will try to get it from catalog endpoint.
* `endpoint_type` - The endpoint type to use : publicURL, adminURL, internalURL. If not provided, vagrant will use publicURL by default.
* `interface_type` - The endpoint type to use for identity v3: public, admin, internal. If not provided, vagrant will use public by default.
* `ssl_ca_file` - The location of CA certificate file.
* `ssl_verify_peer` - Verify peer certificate when connecting to endpoint. Defaults to true. Set to false to disable check (beware this is not secure!)

### Machine Configuration

* `server_name` - The name of the server within OpenStack Cloud. This
  defaults to the name of the Vagrant machine (via `config.vm.define`), but
  can be overridden with this.
* `flavor` - The name of the flavor to use for the VM
* `image` - The name of the image to use for the VM
* `availability_zone` - Nova Availability zone used when creating VM
* `security_groups` - List of strings representing the security groups to apply. e.g. ['ssh', 'http']
* `user_data` - String of User data to be sent to the newly created OpenStack instance. Use this e.g. to inject a script at boot time.
* `metadata` - A Hash of metadata that will be sent to the instance for configuration e.g. `os.metadata  = { 'key' => 'value' }`
* `scheduler_hints` - Pass hints to the OpenStack scheduler, e.g. { "cell": "some cell name" }
* `server_create_timeout` - Time to wait in seconds for the server to be created when `vagrant up`. Default is `200`
* `server_active_timeout` - Time to wait in seconds for the server to become active when `vagrant up` or `vagrant resume`. Default is `200`
* `server_stop_timeout` - Time to wait in seconds for the server to stop when `vagrant halt`. Default is `200`
* `server_delete_timeout` - Time to wait in seconds for the server to be deleted when `vagrant destroy`. Default is `200`

#### Floating IPs

* `floating_ip` - The floating IP to associate with the VM. This IP must be formerly allocated.
* `floating_ip_pool` - The floating IP Pool or a list of floating IP pool from which a floating IP will be allocated to be associated
   with the VM. alternative to the `floating_ip` option.

`floating_ip_pool` attribute can be either a string or an array. In case of an array, if an IP can't be allocated from the first pool
for any reason, it will try with the second one and so on. Finally, if it does not manage to allocate a floating IP from any pools of
the list, it will fail.

```ruby
config.vm.provider :openstack do |os|
  ...
  os.floating_ip_pool = ['External-Network-01', 'External-Network-02']
  ...
end
```

* `floating_ip_pool_always_allocate` - if set to true, vagrant will always allocate floating ip instead of trying to reuse unassigned ones

__N.B.__
> If the instance have a floating IP, this IP will be used to SSH into the instance.

#### Networks

* `ip_version` - What IP version, 4 or 6, should be used to establish the SSH connection to the instance
* `networks` - Network list the server must be connected on. Can be omitted if only one private network exists
  in the OpenStack project

Networking features in the form of `config.vm.network` are not
supported with `vagrant-openstack`, currently. If any of these are
specified, Vagrant will emit a warning, but will otherwise boot
the OpenStack server.

You can provide network id or name. However, in OpenStack a network name is not unique, thus if there are two networks with
the same name in your project the plugin will fail. If so, you have to use only ids. Optionally, you can specify the IP
address that will be assigned to the instance if you need a static address or if DHCP is not enable for this network.

Here's an example which connect the instance to six Networks :

```ruby
config.vm.provider :openstack do |os|
  ...
  os.networks = [
    'net-name-01',
    '287132f0-57e6-4c31-a1ee-4823e9786ff2',
    {
      name: 'net-name-03',
      address: '192.168.22.43'
    },
    {
      id: '7dfdcf01-5177-4774-9473-2ae92a6447d4',
      address: '192.168.43.76'
    },
    {
      name: 'net-name-05'
    },
    {
      id: '01e0950f-c668-4efe-821b-93ff6e427562'
    }
  ]
  ...
end
```

__N.B.__
> If the instance does not have a floating IP, the IP of the
> first network in the list will be used to SSH into the instance

#### Volumes

* `volumes` - Volume list that have to be attached to the server. You can provide volume id or name. However, in OpenStack
a volume name is not unique, thus if there are two volumes with the same name in your project the plugin will fail. If so,
you have to use only ids. Optionally, you can specify the device that will be assigned to the volume.

Here comes an example that show six volumes attached to a server :

```ruby
config.vm.provider :openstack do |os|
  ...
  os.volumes = [
    '619e027c-f4a9-493d-8c15-c89de81cb949',
    'vol-name-02',
    {
      id: '410096ff-ef71-4ca4-8006-e5bd9e99239a',
      device: '/dev/vdc'
    },
    {
      name: 'vol-name-04',
      device: '/dev/vde'
    },
    {
      name: 'vol-name-05'
    },
    {
      id: '9e419e91-8f66-4803-bc45-4600182cfd8d'
    }
  ]
  ...
end
```

* `volume_boot` - Volume to boot the VM from. When booting from an existing volume, `image` is not necessary and must not be provided.

### Orchestration Stacks

* `stacks` - Heat Stacks that will be automatically created when running `vagrant up`, and deleted when running `vagrant destroy`

Here comes an example that show two stacks :

```ruby
config.vm.provider :openstack do |os|
 ...
os.stacks = [
  {
    name: 'mystack1',
    template: 'heat_template.yml'
  }, {
    name: 'mystack2',
    template: '/path/to//my/heat_template.yml'
  }]
end
```

### SSH authentication

* `keypair_name` - The name of the key pair register in nova to associate with the VM. The public key should
  be the matching pair for the private key configured with `config.ssh.private_key_path` on Vagrant. When `config.ssh.insert_key` is `false`, this is ignored.
* `public_key_path` - if `keypair_name` is not provided, the path to the public key will be used by vagrant to generate a keypair on the OpenStack cloud. The keypair will be destroyed when the VM is destroyed. When `config.ssh.insert_key` is `false`, this is ignored.

If neither `keypair_name` nor `public_key_path` are set, vagrant will generate a new ssh key and automatically import it in OpenStack, unless `config.ssh.insert_key` is `false`.

* `ssh_disabled` - if set to `true`, all ssh actions managed by the provider will be disabled during the `vagrant up`.
   We recommend to use this option only to create private VMs that won't be accessed directly from vagrant. By contrast,
   others commands like `vagrant ssh` or `vagrant provision` is run normally but it is likely to fail. Default value is
   `false`.

### Synced folders

**NOTE:** The settings in this section are deprecated. By default, the OpenStack provider will use standard [Vagrant Synced Folders](https://www.vagrantup.com/docs/synced-folders/basic_usage.html). Vagrant's [rsync options](https://www.vagrantup.com/docs/synced-folders/rsync.html) can be configured thusly:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provider :openstack do |provider, override|
    override.vm.synced_folder '.', '/vagrant', type: 'rsync',
      rsync__exclude: ['some/folder/to/exclude']
  end
end
```

Use of the settings described below will cause the OpenStack provider to fall
back to a legacy Rsync implementation that has fewer features. A deprecation
warning will also be printed.


* `sync_method` - Specify the synchronization method for shared folder between the host and the remote VM.
  Currently, it can be "rsync" or "none". The default value is "rsync". If your OpenStack image does not
  include rsync, you must set this parameter to "none".
* `rsync_includes` - If `sync_method` is set to "rsync", this parameter give the list of local folders to sync
  on the remote VM.
* `rsync_ignore_files` - Is used for the rsync prameter "--exclude-from".  Set `rsync_ignore_files` to a list of files
  that contain patterns to exclude from the rsync to /vagrant on a provisioned instance.  ".gitignore  or ".hgignore" for example.

There is minimal support for synced folders. Upon `vagrant up`,
`vagrant reload`, and `vagrant provision`, the OpenStack provider will use
`rsync` (if available) to uni-directionally sync the folder to
the remote machine over SSH.

This is good enough for all built-in Vagrant provisioners (shell,
chef, and puppet) to work!

### HTTP options

* `http.open_timeout` - Open timeout for any HTTP request. Default is `60`
* `http.read_timeout` - Read timeout for any HTTP request. Default is `30`
* `http.proxy` - HTTP Proxy URL to use for all OpenStack API calls

### Provisioners meta-args

We call meta-args, dynamic arguments automatically injected by the vagrant OpenStack provider as
a provisioner argument. The notation for a meta-arg is its name surrounded by double `@` character.

The current implementation supports only shell provisioner.

* `meta_args_support` - Whether meta-args injection is activated or not. Default is `false`

__Available meta-args__

* `@@ssh_ip@@` - The IP used by Vagrant to SSH into the machine

__Usage example__

```ruby
config.vm.provision "shell", inline: 'echo "$1 : $2" > ~/provision', args: ['IP', '@@ssh_ip@@']
```

__N.B.__
> Activate meta-args support causes Vagrant to wrap the built-in provisioning middleware into a custom
  one provided by the OpenStack provider. As a consequence, hooks declared on the built-in provisioning
  middleware will not be applied (see [#248](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/248))


## Vagrant standard configuration

There are some standard configuration options that this provider takes into account when
creating and connecting to OpenStack machines

* `config.vm.box` - A box is not mandatory for this provider. However, if you are running Vagrant before version 1.6, vagrant will not start
   if this property is not set. In this case you can assign any value to it. See section "Box Format" to know more about boxes.
* `config.vm.box_url` - URL of the box when it is necessary
* `ssh.username` - Username used by vagrant for SSH login
* `ssh.port` - Default SSH port is 22. If set, this option will override the default for SSH login
* `ssh.private_key_path` - If set, vagrant will use this private key path to SSH on the machine. If you set this option, the `public_key_path` option of the provider should be set.

## Box Format

Every provider in Vagrant must introduce a custom box format. This
provider introduces `openstack` boxes. You can view an example box in
the [example_box/ directory](https://github.com/ggiamarchi/vagrant-openstack/tree/master/source/example_box).
That directory also contains instructions on how to build a box.

The box format is basically just the required `metadata.json` file
along with a `Vagrantfile` that does default settings for the
provider-specific configuration for this provider.

## Custom commands

Custom commands are provided for OpenStack. Type `vagrant openstack` to
show available commands.

```console
$ vagrant openstack

Usage: vagrant openstack command

Available subcommands:
     image-list           List available images
     flavor-list          List available flavors
     network-list         List private networks in project
     subnet-list          List subnets for available networks
     floatingip-list      List floating IP and floating IP pools
     volume-list          List existing volumes
     reset                Reset Vagrant OpenStack provider to a clear state
```

For instance `vagrant openstack image-list` lists images available in Glance.

```console
$ vagrant openstack image-list

+--------------------------------------+---------------------+
| ID                                   | Name                |
+--------------------------------------+---------------------+
| 594f1287-9de3-4f3e-b82a-6ad223943ab2 | ubuntu-12.04_x86_64 |
| 3e5aca4a-bf12-4721-87df-7bc8fd1fc36c | debian7_x86_64      |
| 3e561121-d8d0-4328-b319-7076bfb3b18a | ubuntu-14.04_x86_64 |
| 5c576643-7ea3-49db-b1c0-9b245d955ee0 | rhel65_x86_64       |
| d3145dd5-654a-4936-b421-9333f02ae66c | centos6_x86_64      |
+--------------------------------------+---------------------+
```

## Contribute

### Development

To work on the `vagrant-openstack` plugin, clone this repository out, and use
[Bundler](http://gembundler.com) to get the dependencies:

Note: Vagrant 1.6 requires bundler version < 1.7. We recommend using last 1.6
version.

```console
$ gem install bundler -v 1.6.6
```

Install the plugin dependencies

```console
$ bundle install
```

Once you have the dependencies, verify the unit tests pass with `rake`:

```console
$ bundle exec rake
```

If those pass, you're ready to start developing the plugin. You can test
the plugin without installing it into your Vagrant environment by just
creating a `Vagrantfile` in the top level of this directory (it is gitignored)
that uses it, and uses bundler to execute Vagrant:

```console
$ bundle exec vagrant up
```

## Troubleshooting

### Logging

To enable all Vagrant logs set environment variable `VAGRANT_LOG` to the desire
log level (for instance `VAGRANT_LOG=debug`). If you want only OpenStack provider
logs use the variable `VAGRANT_OPENSTACK_LOG`. if both variables are set, `VAGRANT_LOG`
takes precedence.

### Version checker

Each time Vagrant OpenStack Provider runs it checks the installed plugin version and
print a warning on stderr if the plugin is not up-to-date.

If for any reason you need to disable this check, set the environment variable
`VAGRANT_OPENSTACK_VERSION_CKECK` to value `DISABLED` prior to run vagrant.

### CentOS/RHEL/Fedora (sudo: sorry, you must have a tty to run sudo)

The default configuration of the RHEL family of Linux distributions requires a
tty in order to run sudo. Vagrant does not connect with a tty by default, so
you may experience the error:
> sudo: sorry, you must have a tty to run sudo

The best way to take deal with this error is to upgrade to Vagrant 1.4 or
later, and enable:
```ruby
config.ssh.pty = true
```
