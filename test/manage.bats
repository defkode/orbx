load helpers/test_helper

ready_ctx() {
  printf '%s\n' korelo > "$ORBX_TMP/list"
  printf '%s\n' korelo > "$ORBX_TMP/running"
  export ORB_STUB_LIST_FIXTURE="$ORBX_TMP/list"
  export ORB_STUB_RUNNING_FIXTURE="$ORBX_TMP/running"
  mkdir -p "$HOME/.orbx/templates"; touch "$HOME/.orbx/templates/default.yaml"
  cd "$PROJECT_DIR"
}

@test "stop calls orb stop" {
  orbx_source; ready_ctx
  run orbx_run stop
  [ "$status" -eq 0 ]
  grep -q "^stop korelo" "$ORB_STUB_LOG"
}

@test "down without --yes refuses when non-interactive" {
  orbx_source; ready_ctx
  run orbx_run down < /dev/null
  [ "$status" -ne 0 ]
  ! grep -q "delete" "$ORB_STUB_LOG"
}

@test "down --yes deletes" {
  orbx_source; ready_ctx
  run orbx_run down --yes
  [ "$status" -eq 0 ]
  grep -q -- "delete -f korelo" "$ORB_STUB_LOG"
}

@test "list passes through to orb list" {
  orbx_source; ready_ctx
  run orbx_run list
  [ "$status" -eq 0 ]
  grep -q "^list" "$ORB_STUB_LOG"
}

@test "ip extracts the address from orb info json" {
  orbx_source; ready_ctx
  printf '%s\n' '{"name":"korelo","ip4":"10.0.1.42"}' > "$ORBX_TMP/info"
  export ORB_STUB_INFO_FIXTURE="$ORBX_TMP/info"
  run orbx_run ip
  [ "$status" -eq 0 ]
  [[ "$output" == *"10.0.1.42"* ]]
}

@test "status shows state, provisioning, and ip" {
  orbx_source; ready_ctx
  printf '%s ' ready > "$ORBX_TMP/seq"; export ORB_STUB_STATUS_SEQ="$ORBX_TMP/seq"
  printf '%s\n' '{"name":"korelo","ip4":"10.0.1.42"}' > "$ORBX_TMP/info"
  export ORB_STUB_INFO_FIXTURE="$ORBX_TMP/info"
  run orbx_run status
  [ "$status" -eq 0 ]
  [[ "$output" == *"running"* ]]
  [[ "$output" == *"ip: 10.0.1.42"* ]]
}
