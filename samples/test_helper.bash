#!/bin/bash

BATS_OUT_LOG=$BATS_TEST_DIRNAME/test.log

setup() {
  title "Setup"

  unset_openstack_env
  export VAGRANT_OPENSTACK_LOG=debug

  source $BATS_TEST_DIRNAME/openrc-keystone-v2.sh

  delete_all_floating_ip >> $BATS_OUT_LOG
  cd $BATS_TEST_DIRNAME/../source
}

teardown() {
  title "Teardown"

  bundle exec vagrant destroy >> $BATS_OUT_LOG

  delete_all_floating_ip >> $BATS_OUT_LOG
  cd $BATS_TEST_DIRNAME
}

unset_openstack_env() {
  for v in $(env | grep OS_ | sed -e "s/\(.*\)=.*/\1/g") ; do  unset $v ; done
}

delete_all_floating_ip() {
  for ip in $(openstack floating ip list | awk '/\| [a-f0-9]/{ print $2 }') ; do
    openstack floating ip delete ${ip}
  done
}

allocate_4_floating_ip() {
  for ip in {1..4} ; do
    openstack floating ip create ${OS_FLOATING_IP_POOL}
  done
}

title() {
  {
    echo ""
    echo "###########################################################"
    echo "### $1"
    echo "###########################################################"
    echo ""  
  } >> $BATS_OUT_LOG
}

flush_out() {
  {
    echo ""
    printf "%s\n" "${lines[@]}"
  } >> $BATS_OUT_LOG
}

exec_vagrant() {
  vagrant $*
}
