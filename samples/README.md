# Samples

This directory contains Vagrantfile examples for the vagrant-openstack-provider.

# Running samples

A [bats](https://github.com/sstephenson/bats) script is available to run all samples as a test
suite.

## Prerequisites

### Script

To run the tests suite you need the following tools:

* Bats
* OpenStack CLI

Values matching your OpenStack information must be set in `openrc-common.sh`, `openrc-keystone-v2.sh` and `openrc-keystone-v3.sh`.

### OpenStack

You need an OpenStack project. This project should be accessible using keyston v2 credentials.

In the projet, the following topology is supposed to exists:

* A router connected to a public network for public access through floating IPs
* A private network connected to the router
* Security group rules and/or firewall rules to allow incomming SSH connections to machines on the private network via floating IPs

## Run

Basically run the executable script `tests.bats`.
