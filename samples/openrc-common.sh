#!/bin/bash

export OS_IMAGE_API_VERSION=2
export OS_REGION_NAME=RegionOne

export OS_FLOATING_IP_ALWAYS_ALLOCATE=false
export OS_FLOATING_IP_POOL_NAME=public
export OS_FLOATING_IP_POOL_ID=5cccfde8-ddae-4feb-9a97-ca6532d1577f
export OS_FLOATING_IP_POOL=${OS_FLOATING_IP_POOL_NAME}

export OS_FLAVOR=m1.small
export OS_IMAGE=Ubuntu-14.04
export OS_NETWORK=net
export OS_SSH_USERNAME=ubuntu
