#!/usr/bin/env bats

load test_helper

@test "03 - Multimachine loop / in parallel" {
  title "$BATS_TEST_DESCRIPTION"

  export VAGRANT_CWD=$BATS_TEST_DIRNAME/03_multimachine_loop

  run exec_vagrant up --parallel
  flush_out
  [ "$status" -eq 0 ]

  run exec_vagrant ssh -c "true" server-1
  flush_out
  [ "$status" -eq 0 ]

  run exec_vagrant ssh -c "true" server-2
  flush_out
  [ "$status" -eq 0 ]

  run exec_vagrant ssh -c "true" server-3
  flush_out
  [ "$status" -eq 0 ]

  run exec_vagrant ssh -c "true" server-4
  flush_out
  [ "$status" -eq 0 ]

  run exec_vagrant ssh -c "true" server-5
  flush_out
  [ "$status" -eq 0 ]

  run exec_vagrant ssh -c "true" server-6
  flush_out
  [ "$status" -eq 0 ]

  run exec_vagrant destroy
  flush_out
  [ "$status" -eq 0 ]
}
