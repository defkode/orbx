load helpers/test_helper

@test "machine_exists true when name is in orb list -q" {
  orbx_source
  printf '%s\n' korelo shopdesk > "$ORBX_TMP/list"
  export ORB_STUB_LIST_FIXTURE="$ORBX_TMP/list"
  run orbx::machine_exists korelo
  [ "$status" -eq 0 ]
}

@test "machine_exists false when name absent" {
  orbx_source
  printf '%s\n' shopdesk > "$ORBX_TMP/list"
  export ORB_STUB_LIST_FIXTURE="$ORBX_TMP/list"
  run orbx::machine_exists korelo
  [ "$status" -ne 0 ]
}

@test "machine_running reflects orb list -r -q" {
  orbx_source
  printf '%s\n' korelo > "$ORBX_TMP/running"
  export ORB_STUB_RUNNING_FIXTURE="$ORBX_TMP/running"
  run orbx::machine_running korelo
  [ "$status" -eq 0 ]
  run orbx::machine_running shopdesk
  [ "$status" -ne 0 ]
}
