# -*- mode: ruby -*-
# vi: set ft=ruby :

$script = <<SCRIPT
export DEBIAN_FRONTEND=noninteractive
apt-add-repository ppa:brightbox/ruby-ng
apt-get update
apt-get upgrade -y
apt-get install -y git ruby-switch ruby2.0 ruby2.0-dev
ruby-switch --set ruby2.0
gem install bundler -v 1.6.6
su -c 'cd /vagrant/source; bundle install --path /home/vagrant/.gem'
chown -R vagrant:vagrant /home/vagrant/.gem
SCRIPT

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.hostname = "openstack"
  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"
  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus = 2
  end
  config.vm.provision "shell", inline: $script
end
