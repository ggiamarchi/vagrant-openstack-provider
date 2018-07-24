#!/usr/bin/env bats

load test_helper

@test "01 - Simple - with floating IPs pre-allocated / using floating IP pool name / don't force allocate" {
  title "$BATS_TEST_DESCRIPTION"

  allocate_4_floating_ip
  [ $(openstack floating ip list -f value | wc -l) -eq 4 ] # Check 4 IPs are allocated

  export VAGRANT_CWD=$BATS_TEST_DIRNAME/01_simple
  export OS_FLOATING_IP_ALWAYS_ALLOCATE=false
  export OS_FLOATING_IP_POOL=${OS_FLOATING_IP_POOL_NAME}

  run exec_vagrant up
  flush_out
  [ "$status" -eq 0 ]
  [ $(openstack floating ip list -f value | wc -l) -eq 4 ] # Check again 4 IPs are allocated

  run exec_vagrant ssh -c "true"
  flush_out
  [ "$status" -eq 0 ]

  run exec_vagrant destroy
  flush_out
  [ "$status" -eq 0 ]
}
