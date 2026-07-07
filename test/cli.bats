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

@test "sourcing bin/orbx defines functions without running main" {
  orbx_source
  [ "$(type -t orbx::version)" = "function" ]
  [ "$(type -t orbx::main)" = "function" ]
}

@test "the fake orb on PATH records its argv" {
  run orb list --quiet
  [ "$status" -eq 0 ]
  grep -q "list --quiet" "$ORB_STUB_LOG"
}
