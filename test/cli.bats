load helpers/test_helper

@test "--version prints the version" {
  run orbx_run --version
  [ "$status" -eq 0 ]
  [[ "$output" == "orbx 0.1.0" ]]
}

@test "unknown command exits non-zero" {
  run orbx_run bogus-command
  [ "$status" -ne 0 ]
}
