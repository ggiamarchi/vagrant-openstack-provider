#!/usr/bin/env bats

load test_helper

@test "01 - Simple - without any floating IP pre-allocated / using floating IP pool name / don't force allocate" {
  title "$BATS_TEST_DESCRIPTION"

  export VAGRANT_CWD=$BATS_TEST_DIRNAME/01_simple
  export OS_FLOATING_IP_POOL=${OS_FLOATING_IP_POOL_NAME}

  [ $(openstack floating ip list -f value | wc -l) -eq 0 ] # Check no IPs is allocated

  run exec_vagrant up
  flush_out
  [ "$status" -eq 0 ]
  [ $(openstack floating ip list -f value | wc -l) -eq 1 ] # Check one IP is allocated

  run exec_vagrant ssh -c "true"
  flush_out
  [ "$status" -eq 0 ]

  run exec_vagrant destroy
  flush_out
  [ "$status" -eq 0 ]
}
