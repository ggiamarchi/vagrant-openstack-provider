# Vagrant Openstack Cloud Provider

[![Build Status](https://api.travis-ci.org/ggiamarchi/vagrant-openstack-provider.png?branch=master)](https://travis-ci.org/ggiamarchi/vagrant-openstack-provider)
[![Gem Version](https://badge.fury.io/rb/vagrant-openstack-provider.svg)](http://badge.fury.io/rb/vagrant-openstack-provider)
[![Code Climate](https://codeclimate.com/github/ggiamarchi/vagrant-openstack-provider.png)](https://codeclimate.com/github/ggiamarchi/vagrant-openstack-provider)

This is a [Vagrant](http://www.vagrantup.com) 1.4+ plugin that adds a
[Openstack Cloud](http://www.openstack.org/software/) provider to Vagrant,
allowing Vagrant to control and provision machines within Openstack
cloud.

**Note:** This plugin was originally forked from [mitchellh/vagrant-rackspace](https://github.com/mitchellh/vagrant-rackspace)

## Features

* Create and boot Openstack instances
* Halt and reboot instances
* Suspend and resume instances
* SSH into the instances
* Automatic SSH key generation and Nova public key provisioning
* Automatic floating IP allocation and association
* Provision the instances with any built-in Vagrant provisioner
* Boot instance from volume
* Attach Cinder volumes to the instances
* Minimal synced folder support via `rsync`
* Custom sub-commands within Vagrant CLI to query Openstack objects

## Usage

Install using standard Vagrant 1.1+ plugin installation methods. After
installing, `vagrant up` and specify the `openstack` provider. An example is
shown below.

```
$ vagrant plugin install vagrant-openstack-provider
...
$ vagrant up --provider=openstack
...
```

Of course prior to doing this, you'll need to obtain an Openstack-compatible
box file for Vagrant.

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
```

And then run `vagrant up --provider=openstack`.

Note that normally a lot of this boilerplate is encoded within the box
file, but the box file used for the quick start, the "dummy" box, has
no preconfigured defaults.

## Box Format

Every provider in Vagrant must introduce a custom box format. This
provider introduces `openstack` boxes. You can view an example box in
the [example_box/ directory](https://github.com/ggiamarchi/vagrant-openstack/tree/master/source/example_box).
That directory also contains instructions on how to build a box.

The box format is basically just the required `metadata.json` file
along with a `Vagrantfile` that does default settings for the
provider-specific configuration for this provider.

## Configuration

This provider exposes quite a few provider-specific configuration options:

### Credentials

* `username` - The username with which to access Openstack.
* `password` - The API key for accessing Openstack.
* `tenant_name` - The Openstack project name to work on
* `openstack_auth_url` - The endpoint to authentication against. By default, vagrant will use the global
openstack authentication endpoint for all regions with the exception of :lon. IF :lon region is specified
vagrant will authenticate against the UK authentication endpoint.
* `openstack_compute_url` - The compute service URL to hit. This is good for custom endpoints. If not provided, vagrant will try to get it from catalog endpoint.
* `openstack_network_url` - The network service URL to hit. This is good for custom endpoints. If not provided, vagrant will try to get it from catalog endpoint.
* `openstack_volume_url` - The block storage URL to hit. This is good for custom endpoints. If not provided, vagrant will try to get it from catalog endpoint.

### VM Configuration

* `server_name` - The name of the server within Openstack Cloud. This
  defaults to the name of the Vagrant machine (via `config.vm.define`), but
  can be overridden with this.
* `flavor` - The name of the flavor to use for the VM
* `image` - The name of the image to use for the VM
* `floating_ip` - The floating IP to associate with the VM. This IP must be formerly allocated.
* `floating_ip_pool` - The floating IP Pool from which a floating IP will be allocated to be associated with the VM. alternative to the `floating_ip` option.
* `floating_ip_pool_always_allocate` - if set to true, vagrant will always allocate floating ip instead of trying to reuse unassigned ones
* `availability_zone` - Nova Availability zone used when creating VM
* `security_groups` - List of strings representing the security groups to apply. e.g. ['ssh', 'http']
* `user_data` - String of User data to be sent to the newly created OpenStack instance. Use this e.g. to inject a script at boot time.
* `metadata` - A Hash of metadata that will be sent to the instance for configuration e.g. `os.metadata  = { 'key' => 'value' }`
* `scheduler_hints` - Pass hints to the OpenStack scheduler, e.g. { "cell": "some cell name" }

#### Networks

* `networks` - Network list the server must be connected on. Can be omitted if only one private network exists
  in the Openstack project

Networking features in the form of `config.vm.network` are not
supported with `vagrant-openstack`, currently. If any of these are
specified, Vagrant will emit a warning, but will otherwise boot
the Openstack server.

You can provide network id or name. However, in Openstack a network name is not unique, thus if there is two networks with
the same name in your project the plugin will fail. If so, you have to use only ids.

Here's an example which adds two Cloud Networks. The first by id and the second by name.

```ruby
config.vm.provider :openstack do |os|
  ...
  os.networks = ['443aff42-be57-effb-ad30-c097c1e4503f', 'backend-network']
  ...
end
```

#### Volumes

* `volumes` - Volume list that have to be attached to the server. You can provide volume id or name. However, in Openstack
a volume name is not unique, thus if there is two volumes with the same name in your project the plugin will fail. If so,
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
end
```

* `volume_boot` - Volume to boot the VM from. When booting from an existing volume, `image` is not necessary and must not be provided.

### SSH-key authentication

* `keypair_name` - The name of the key pair register in nova to associate with the VM. The public key should
  be the matching pair for the private key configured with `config.ssh.private_key_path` on Vagrant.
* `public_key_path` - if `keypair_name` is not provided, the path to the public key will be used by vagrant to generate a keypair on the OpenStack cloud. The keypair will be destroyed when the VM is destroyed.

If neither `keypair_name` nor `public_key_path` are set, vagrant will generate a new ssh key and automatically import it in Openstack.

### Synced folders

* `sync_method` - Specify the synchronization method for shared folder between the host and the remote VM.
  Currently, it can be "rsync" or "none". The default value is "rsync". If your Openstack image does not
  include rsync, you must set this parameter to "none".
* `rsync_includes` - If `sync_method` is set to "rsync", this parameter give the list of local folders to sync
  on the remote VM.

There is minimal support for synced folders. Upon `vagrant up`,
`vagrant reload`, and `vagrant provision`, the Openstack provider will use
`rsync` (if available) to uni-directionally sync the folder to
the remote machine over SSH.

This is good enough for all built-in Vagrant provisioners (shell,
chef, and puppet) to work!

## Vagrant standard configuration

There are some standard configuration options that this provider takes into account when
creating and connecting to OpenStack machines

* `ssh.username` - Username used by vagrant for SSH login
* `ssh.port` - Default SSH port is 22. If set, this option will override the default for SSH login
* `ssh.private_key_path` - If set, vagrant will use this private key path to SSH on the machine. If you set this option, the `public_key_path` option of the provider should be set.

## Custom commands

Custom commands are provided for Openstack. Type `vagrant openstack` to
show available commands.

```
$ vagrant openstack

Usage: vagrant openstack command

Available subcommands:
     image-list           List available images
     flavor-list          List available flavors
     network-list         List private networks in project
     floatingip-list      List floating IP and floating IP pools
     volume-list          List existing volumes
     reset                Reset Vagrant OpenStack provider to a clear state
```

For instance `vagrant openstack image-list` lists images available in Glance.

```
$ vagrant openstack image-list

+--------------------------------------+---------------------+
| 'Id'                                 | 'Name'              |
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

```
$ gem install bundler -v 1.6.6
```

Install the plugin dependencies

```
$ bundle install
```

Once you have the dependencies, verify the unit tests pass with `rake`:

```
$ bundle exec rake
```

If those pass, you're ready to start developing the plugin. You can test
the plugin without installing it into your Vagrant environment by just
creating a `Vagrantfile` in the top level of this directory (it is gitignored)
that uses it, and uses bundler to execute Vagrant:

```
$ bundle exec vagrant up --provider=openstack
```

## Troubleshooting

### Logging

To enable all Vagrant logs set environment variable `VAGRANT_LOG` to the desire
log level (for instance `VAGRANT_LOG=debug`). If you want only Openstack provider
logs use the variable `VAGRANT_OPENSTACK_LOG`. if both variables are set, `VAGRANT_LOG`
takes precedence.


### CentOS/RHEL/Fedora (sudo: sorry, you must have a tty to run sudo)

The default configuration of the RHEL family of Linux distributions requires a
tty in order to run sudo. Vagrant does not connect with a tty by default, so
you may experience the error:
> sudo: sorry, you must have a tty to run sudo

The best way to take deal with this error is to upgrade to Vagrant 1.4 or
later, and enable:
```
config.ssh.pty = true
```

## Sponsoring

[![Numergy](https://www.numergy.com/images/general/numergy-logo.png)](http://www.numergy.com)


We thanks [Numergy](http://www.numergy.com) for giving us access to free compute resources on their OpenStack cloud that enabled us to test our provider on a real OpenStack installation.

If you are also powering an OpenStack cloud, we'd like to hear from you. Test
the plugin and report us issues or features you'd like to see. 
