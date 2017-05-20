#!/bin/bash

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export OS_AUTH_URL=http://openstack:5000/v2.0
export OS_IDENTITY_API_VERSION=2
export OS_TENANT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=admin

source ${script_dir}/openrc-common.sh
