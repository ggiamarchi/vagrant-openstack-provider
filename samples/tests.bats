#!/usr/bin/env bats

load test_helper

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
  cd $BATS_TEST_DIRNAME
}

@test "01 - Simple - without any floating IP pre-allocated / using floating IP pool name / don't force allocate" {
  title "$BATS_TEST_DESCRIPTION"

  export VAGRANT_CWD=$BATS_TEST_DIRNAME/01_simple
  export OS_FLOATING_IP_POOL=${OS_FLOATING_IP_POOL_NAME}

  [ $(openstack floating ip list -f value | wc -l) -eq 0 ] # Check no IPs is allocated

  run bundle exec vagrant up
  flush_out
  [ "$status" -eq 0 ]
  [ $(openstack floating ip list -f value | wc -l) -eq 1 ] # Check one IP is allocated
  
  run bundle exec vagrant ssh -c "true"
  flush_out
  [ "$status" -eq 0 ]
  
  run bundle exec vagrant destroy
  flush_out
  [ "$status" -eq 0 ]
}

@test "01 - Simple - without any floating IP pre-allocated / using floating IP pool ID / don't force allocate" {
  title "$BATS_TEST_DESCRIPTION"

  export VAGRANT_CWD=$BATS_TEST_DIRNAME/01_simple
  export OS_FLOATING_IP_POOL=${OS_FLOATING_IP_POOL_ID}

  [ $(openstack floating ip list -f value | wc -l) -eq 0 ] # Check no IPs is allocated

  run bundle exec vagrant up
  flush_out
  [ "$status" -eq 0 ]
  [ $(openstack floating ip list -f value | wc -l) -eq 1 ] # Check one IP is allocated

  run bundle exec vagrant ssh -c "true"
  flush_out
  [ "$status" -eq 0 ]

  run bundle exec vagrant destroy
  flush_out
  [ "$status" -eq 0 ]
}

@test "01 - Simple - with floating IPs pre-allocated / using floating IP pool name / don't force allocate" {
  title "$BATS_TEST_DESCRIPTION"

  allocate_4_floating_ip
  [ $(openstack floating ip list -f value | wc -l) -eq 4 ] # Check 4 IPs are allocated

  export VAGRANT_CWD=$BATS_TEST_DIRNAME/01_simple
  export OS_FLOATING_IP_ALWAYS_ALLOCATE=false
  export OS_FLOATING_IP_POOL=${OS_FLOATING_IP_POOL_NAME}

  run bundle exec vagrant up
  flush_out
  [ "$status" -eq 0 ]
  [ $(openstack floating ip list -f value | wc -l) -eq 4 ] # Check again 4 IPs are allocated

  run bundle exec vagrant ssh -c "true"
  flush_out
  [ "$status" -eq 0 ]

  run bundle exec vagrant destroy
  flush_out
  [ "$status" -eq 0 ]
}

@test "01 - Simple - with floating IPs pre-allocated / using floating IP pool name / force allocate" {
  title "$BATS_TEST_DESCRIPTION"

  allocate_4_floating_ip
  [ $(openstack floating ip list -f value | wc -l) -eq 4 ] # Check 4 IPs are allocated

  export VAGRANT_CWD=$BATS_TEST_DIRNAME/01_simple
  export OS_FLOATING_IP_ALWAYS_ALLOCATE=true
  export OS_FLOATING_IP_POOL=${OS_FLOATING_IP_POOL_NAME}

  run bundle exec vagrant up
  flush_out
  [ "$status" -eq 0 ]
  [ $(openstack floating ip list -f value | wc -l) -eq 5 ] # Check again 4 IPs are allocated

  run bundle exec vagrant ssh -c "true"
  flush_out
  [ "$status" -eq 0 ]

  run bundle exec vagrant destroy
  flush_out
  [ "$status" -eq 0 ]
}

# TODO This test fails because of issue #325
@test "01 - Simple - with floating IPs pre-allocated / using floating IP pool ID / don't force allocate" {
  title "$BATS_TEST_DESCRIPTION"
  skip

  allocate_4_floating_ip
  [ $(openstack floating ip list -f value | wc -l) -eq 4 ] # Check 4 IPs are allocated

  export VAGRANT_CWD=$BATS_TEST_DIRNAME/01_simple
  export OS_FLOATING_IP_ALWAYS_ALLOCATE=false
  export OS_FLOATING_IP_POOL=${OS_FLOATING_IP_POOL_ID}

  run bundle exec vagrant up
  flush_out
  [ "$status" -eq 0 ]
  [ $(openstack floating ip list -f value | wc -l) -eq 4 ] # Check again 4 IPs are allocated

  run bundle exec vagrant ssh -c "true"
  flush_out
  [ "$status" -eq 0 ]

  run bundle exec vagrant destroy
  flush_out
  [ "$status" -eq 0 ]
}

@test "01 - Simple - with floating IPs pre-allocated / using floating IP pool ID / force allocate" {
  title "$BATS_TEST_DESCRIPTION"

  allocate_4_floating_ip
  [ $(openstack floating ip list -f value | wc -l) -eq 4 ] # Check 4 IPs are allocated

  export VAGRANT_CWD=$BATS_TEST_DIRNAME/01_simple
  export OS_FLOATING_IP_ALWAYS_ALLOCATE=true
  export OS_FLOATING_IP_POOL=${OS_FLOATING_IP_POOL_ID}

  run bundle exec vagrant up
  flush_out
  [ "$status" -eq 0 ]
  [ $(openstack floating ip list -f value | wc -l) -eq 5 ] # Check again 4 IPs are allocated

  run bundle exec vagrant ssh -c "true"
  flush_out
  [ "$status" -eq 0 ]

  run bundle exec vagrant destroy
  flush_out
  [ "$status" -eq 0 ]
}

@test "02 - Multimachine" {
  title "$BATS_TEST_DESCRIPTION"

  export VAGRANT_CWD=$BATS_TEST_DIRNAME/02_multimachine

  run bundle exec vagrant up
  flush_out
  [ "$status" -eq 0 ]

  run bundle exec vagrant ssh -c "true" server-1
  flush_out
  [ "$status" -eq 0 ]

  run bundle exec vagrant ssh -c "true" server-2
  flush_out
  [ "$status" -eq 0 ]

  run bundle exec vagrant destroy
  flush_out
  [ "$status" -eq 0 ]
}

@test "03 - Multimachine loop" {
  title "$BATS_TEST_DESCRIPTION"

  export VAGRANT_CWD=$BATS_TEST_DIRNAME/03_multimachine_loop

  run bundle exec vagrant up
  flush_out
  [ "$status" -eq 0 ]

  run bundle exec vagrant ssh -c "true" server-1
  flush_out
  [ "$status" -eq 0 ]

  run bundle exec vagrant ssh -c "true" server-2
  flush_out
  [ "$status" -eq 0 ]

  run bundle exec vagrant ssh -c "true" server-3
  flush_out
  [ "$status" -eq 0 ]

  run bundle exec vagrant destroy
  flush_out
  [ "$status" -eq 0 ]
}

@test "04 - Heat Stack" {
  title "$BATS_TEST_DESCRIPTION"

  export VAGRANT_CWD=$BATS_TEST_DIRNAME/04_heat_stack

  run bundle exec vagrant up
  flush_out
  [ "$status" -eq 0 ]

  run bundle exec vagrant ssh -c "true" server-1
  flush_out
  [ "$status" -eq 0 ]

  run bundle exec vagrant ssh -c "true" server-2
  flush_out
  [ "$status" -eq 0 ]

  run bundle exec vagrant destroy
  flush_out
  [ "$status" -eq 0 ]
}

@test "05 - Keystone v3" {
  title "$BATS_TEST_DESCRIPTION"

  source $BATS_TEST_DIRNAME/openrc-keystone-v3.sh

  export VAGRANT_CWD=$BATS_TEST_DIRNAME/05_keystone_v3

  run bundle exec vagrant up
  flush_out
  [ "$status" -eq 0 ]

  run bundle exec vagrant ssh -c "true"
  flush_out
  [ "$status" -eq 0 ]

  run bundle exec vagrant destroy
  flush_out
  [ "$status" -eq 0 ]
}

@test "06 - With config.ssh.insert_key = false" {
  title "$BATS_TEST_DESCRIPTION"

  export VAGRANT_CWD=$BATS_TEST_DIRNAME/06_insert_key_false

  run bundle exec vagrant up
  flush_out
  [ "$status" -eq 0 ]

  run bundle exec vagrant ssh -c "true"
  flush_out
  [ "$status" -eq 0 ]

  run bundle exec vagrant destroy
  flush_out
  [ "$status" -eq 0 ]
}
