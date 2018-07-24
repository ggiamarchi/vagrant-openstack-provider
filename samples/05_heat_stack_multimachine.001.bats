#!/usr/bin/env bats

load test_helper

@test "05 - Heat Stack multimachine" {
  skip "Does not work currently"
  title "$BATS_TEST_DESCRIPTION"

  export VAGRANT_CWD=$BATS_TEST_DIRNAME/05_heat_stack_multimachine

  run exec_vagrant up
  flush_out
  [ "$status" -eq 0 ]

  run exec_vagrant ssh -c "true" server-1
  flush_out
  [ "$status" -eq 0 ]

  run exec_vagrant ssh -c "true" server-2
  flush_out
  [ "$status" -eq 0 ]

  run exec_vagrant destroy
  flush_out
  [ "$status" -eq 0 ]
}
