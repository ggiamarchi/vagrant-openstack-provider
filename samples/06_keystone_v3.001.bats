#!/usr/bin/env bats

load test_helper

@test "06 - Keystone v3" {
  title "$BATS_TEST_DESCRIPTION"

  unset_openstack_env
  source $BATS_TEST_DIRNAME/openrc-keystone-v3.sh

  export VAGRANT_CWD=$BATS_TEST_DIRNAME/06_keystone_v3

  run exec_vagrant up
  flush_out
  [ "$status" -eq 0 ]

  run exec_vagrant ssh -c "true"
  flush_out
  [ "$status" -eq 0 ]

  run exec_vagrant destroy
  flush_out
  [ "$status" -eq 0 ]
}

