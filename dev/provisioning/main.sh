#!/bin/bash

set -ex

### Install ruby

sudo apt update
sudo apt install -y ruby2.7 ruby2.7-dev build-essential
sudo gem install bundler

### build project

cd /vagrant/source
bundle install

### Remove old .vagrant dir for test Vagrantfile

rm -rf /vagrant/dev/test/.vagrant/

### Set vagrant command to run openstack provider from sources

cat >> .bashrc <<'EOF'

vagrant() {
    RUN_DIR=$PWD
    (
        cd /vagrant/source
        VAGRANT_OPENSTACK_LOG=debug VAGRANT_CWD=${RUN_DIR} bundle exec vagrant $*
    )
}
EOF

### Create stack user for Devstack

sudo useradd -s /bin/bash -d /opt/stack -m stack
sudo chmod +x /opt/stack
echo "stack ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/stack

### Install devstack in background

sudo -u stack -s -- <<'EOF'
nohup /vagrant/dev/provisioning/devstack.sh > $HOME/devstack.log 2>&1 &
EOF

set +x

echo ""
echo ""
echo " !!!   Devstack installation process is running in backgroud              !!!"
echo " !!!   It can take a while, mainly depending on your internet bandwidth   !!!"
echo " !!!                                                                      !!!"
echo " !!!   See progress in /opt/stack/devstack.log                            !!!"
echo ""
echo ""
