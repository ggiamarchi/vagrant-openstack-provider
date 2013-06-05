# Vagrant RackSpace Cloud Provider

This is a [Vagrant](http://www.vagrantup.com) 1.1+ plugin that adds a
[RackSpace Cloud](http://www.rackspace.com/cloud) provider to Vagrant,
allowing Vagrant to control and provision machines within RackSpace
cloud.

**Note:** This plugin requires Vagrant 1.1+.

## Features

* Boot Rackspace Cloud instances.
* SSH into the instances.
* Provision the instances with any built-in Vagrant provisioner.
* Minimal synced folder support via `rsync`.

## Usage

Install using standard Vagrant 1.1+ plugin installation methods. After
installing, `vagrant up` and specify the `rackspace` provider. An example is
shown below.

```
$ vagrant plugin install vagrant-rackspace
...
$ vagrant up --provider=rackspace
...
```

Of course prior to doing this, you'll need to obtain an Rackspace-compatible
box file for Vagrant.

## Quick Start

After installing the plugin (instructions above), the quickest way to get
started is to actually use a dummy Rackspace box and specify all the details
manually within a `config.vm.provider` block. So first, add the dummy
box using any name you want:

```
$ vagrant box add dummy https://github.com/mitchellh/vagrant-rackspace/raw/master/dummy.box
...
```

And then make a Vagrantfile that looks like the following, filling in
your information where necessary.

```
Vagrant.configure("2") do |config|
  config.vm.box = "dummy"

  config.vm.provider :rackspace do |rs|
    rs.username = "YOUR USERNAME"
    rs.api_key  = "YOUR API KEY"
    rs.flavor   = /512MB/
    rs.image    = /Ubuntu/
  end
end
```

And then run `vagrant up --provider=rackspace`.

This will start an Ubuntu 12.04 instance in the DFW datacenter region within
your account. And assuming your SSH information was filled in properly
within your Vagrantfile, SSH and provisioning will work as well.

Note that normally a lot of this boilerplate is encoded within the box
file, but the box file used for the quick start, the "dummy" box, has
no preconfigured defaults.

## Box Format

Every provider in Vagrant must introduce a custom box format. This
provider introduces `rackspace` boxes. You can view an example box in
the [example_box/ directory](https://github.com/mitchellh/vagrant-rackspace/tree/master/example_box).
That directory also contains instructions on how to build a box.

The box format is basically just the required `metadata.json` file
along with a `Vagrantfile` that does default settings for the
provider-specific configuration for this provider.

## Configuration

This provider exposes quite a few provider-specific configuration options:

* `api_key` - The API key for accessing Rackspace.
* `flavor` - The server flavor to boot. This can be a string matching
  the exact ID or name of the server, or this can be a regular expression
  to partially match some server flavor.
* `image` - The server image to boot. This can be a string matching the
  exact ID or name of the image, or this can be a regular expression to
  partially match some image.
* `rackspace_region` - The region to hit. By default this is :dfw. Valid options are: 
:dfw, :ord, :lon.  User this OR rackspace_compute_url
* `rackspace_compute_url` - The compute_url to hit. This is good for custom endpoints. 
Use this OR rackspace_region.
* `public_key_path` - The path to a public key to initialize with the remote
  server. This should be the matching pair for the private key configured
  with `config.ssh.private_key_path` on Vagrant.
* `server_name` - The name of the server within RackSpace Cloud. This
  defaults to the name of the Vagrant machine (via `config.vm.define`), but
  can be overridden with this.
* `username` - The username with which to access Rackspace.

These can be set like typical provider-specific configuration:

```ruby
Vagrant.configure("2") do |config|
  # ... other stuff

  config.vm.provider :rackspace do |rs|
    rs.username = "mitchellh"
    rs.api_key  = "foobarbaz"
  end
end
```

## Networks

Networking features in the form of `config.vm.network` are not
supported with `vagrant-rackspace`, currently. If any of these are
specified, Vagrant will emit a warning, but will otherwise boot
the Rackspace server.

## Synced Folders

There is minimal support for synced folders. Upon `vagrant up`,
`vagrant reload`, and `vagrant provision`, the Rackspace provider will use
`rsync` (if available) to uni-directionally sync the folder to
the remote machine over SSH.

This is good enough for all built-in Vagrant provisioners (shell,
chef, and puppet) to work!

## Development

To work on the `vagrant-rackspace` plugin, clone this repository out, and use
[Bundler](http://gembundler.com) to get the dependencies:

```
$ bundle
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
$ bundle exec vagrant up --provider=rackspace
```
