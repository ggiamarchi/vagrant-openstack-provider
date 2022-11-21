#!/bin/bash

set -ex

wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt install -y vagrant

vagrant plugin install vagrant-openstack-provider

mkdir $HOME/vagrant
cd $HOME/vagrant

cat > Vagrantfile <<'EOF'
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure('2') do |config|

  config.ssh.username = 'ubuntu'
  config.vm.boot_timeout = 500

  config.vm.provider :openstack do |os, ov|
    os.server_name                      = 'vagrant'

    os.identity_api_version             = '3'
    os.domain_name                      = ENV['OS_PROJECT_DOMAIN_ID']
    os.project_name                     = ENV['OS_PROJECT_NAME']
    os.openstack_auth_url               = ENV['OS_AUTH_URL'] + '/v3'
    os.username                         = ENV['OS_USERNAME']
    os.password                         = ENV['OS_PASSWORD']
    os.region                           = ENV['OS_REGION_NAME']
    os.floating_ip_pool                 = 'public'
    os.floating_ip_pool_always_allocate = true
    os.flavor                           = 'ds512M'
    os.image                            = 'ubuntu-18.04'
    os.networks                         = ['private']
    os.security_groups                  = ['default']

    os.openstack_network_url = 'http://10.0.2.15:9696/networking/v2.0'

    ov.nfs.functional = false
  end
end
EOF

source $HOME/devstack/openrc
VAGRANT_OPENSTACK_LOG=debug vagrant up
