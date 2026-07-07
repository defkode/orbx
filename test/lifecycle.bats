load helpers/test_helper

@test "wait_ready returns 0 when status reaches ready" {
  orbx_source
  printf '%s ' provisioning provisioning ready > "$ORBX_TMP/seq"
  export ORB_STUB_STATUS_SEQ="$ORBX_TMP/seq"
  run orbx::wait_ready korelo
  [ "$status" -eq 0 ]
}

@test "wait_ready aborts immediately on failed" {
  orbx_source
  printf '%s ' provisioning failed > "$ORBX_TMP/seq"
  export ORB_STUB_STATUS_SEQ="$ORBX_TMP/seq"
  run orbx::wait_ready korelo
  [ "$status" -ne 0 ]
  [[ "$output" == *"orbx logs"* ]]
}

@test "wait_ready times out when never ready" {
  orbx_source
  printf '%s ' provisioning provisioning provisioning > "$ORBX_TMP/seq"
  export ORB_STUB_STATUS_SEQ="$ORBX_TMP/seq"
  export ORBX_READY_TIMEOUT=0
  run orbx::wait_ready korelo
  [ "$status" -ne 0 ]
  [[ "$output" == *"logs"* ]]
}

@test "ensure_up creates when the machine is absent" {
  orbx_source
  : > "$ORBX_TMP/list"                          # no machines
  export ORB_STUB_LIST_FIXTURE="$ORBX_TMP/list"
  printf '%s ' ready > "$ORBX_TMP/seq"
  export ORB_STUB_STATUS_SEQ="$ORBX_TMP/seq"
  mkdir -p "$HOME/.orbx/templates"; touch "$HOME/.orbx/templates/default.yaml"
  cd "$PROJECT_DIR"
  run orbx_run up
  [ "$status" -eq 0 ]
  grep -q "create -c" "$ORB_STUB_LOG"
}

@test "ensure_up starts when the machine exists but is stopped" {
  orbx_source
  printf '%s\n' korelo > "$ORBX_TMP/list"       # exists
  : > "$ORBX_TMP/running"                        # not running
  export ORB_STUB_LIST_FIXTURE="$ORBX_TMP/list"
  export ORB_STUB_RUNNING_FIXTURE="$ORBX_TMP/running"
  printf '%s ' ready > "$ORBX_TMP/seq"
  export ORB_STUB_STATUS_SEQ="$ORBX_TMP/seq"
  mkdir -p "$HOME/.orbx/templates"; touch "$HOME/.orbx/templates/default.yaml"
  cd "$PROJECT_DIR"
  run orbx_run up
  [ "$status" -eq 0 ]
  grep -q "^start korelo" "$ORB_STUB_LOG"
  ! grep -q "create -c" "$ORB_STUB_LOG"
}
