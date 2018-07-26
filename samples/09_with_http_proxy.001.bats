#!/usr/bin/env bats

load test_helper

@test "09 - With HTTP Proxy" {
  title "$BATS_TEST_DESCRIPTION"

  export VAGRANT_CWD=$BATS_TEST_DIRNAME/09_with_http_proxy

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
