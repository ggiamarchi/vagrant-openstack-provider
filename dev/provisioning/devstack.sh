#!/bin/bash

set -ex

cd $HOME

### Prepare host

sudo apt install -y net-tools

### Get Devstack sources

git clone https://opendev.org/openstack/devstack
cd devstack

### Create devstack configuration

cat > local.conf <<'EOF'
[[local|localrc]]
ADMIN_PASSWORD=secret
DATABASE_PASSWORD=$ADMIN_PASSWORD
RABBIT_PASSWORD=$ADMIN_PASSWORD
SERVICE_PASSWORD=$ADMIN_PASSWORD
EOF

HOST_IP=$(ip route | grep -e "^default" | sed -e "s/.* src \([^ ]*\) .*/\1/")

cat >> local.conf <<EOF
HOST_IP=${HOST_IP}
EOF

### Run install process

./stack.sh

### Set credentials

source $HOME/devstack/openrc

### Configure default security group (everything open)

openstack security group rule list | grep -v '| ID ' | grep '| ' | awk '{ print $2 }' | while read id ; do openstack security group rule delete $id ; done

openstack security group rule create --protocol tcp --ethertype IPv4 --ingress default
openstack security group rule create --protocol tcp --ethertype IPv4 --egress default
openstack security group rule create --protocol udp --ethertype IPv4 --ingress default
openstack security group rule create --protocol udp --ethertype IPv4 --egress default
openstack security group rule create --protocol icmp --ethertype IPv4 --ingress default
openstack security group rule create --protocol icmp --ethertype IPv4 --egress default

### Create Ubuntu image

wget -O /tmp/ubuntu-18.04.img https://cloud-images.ubuntu.com/releases/bionic/release/ubuntu-18.04-server-cloudimg-amd64.img
openstack image create --disk-format qcow2 --file /tmp/ubuntu-18.04.img ubuntu-18.04
