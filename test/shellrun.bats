load helpers/test_helper

setup_ready_machine() {
  printf '%s\n' korelo > "$ORBX_TMP/list"
  printf '%s\n' korelo > "$ORBX_TMP/running"
  export ORB_STUB_LIST_FIXTURE="$ORBX_TMP/list"
  export ORB_STUB_RUNNING_FIXTURE="$ORBX_TMP/running"
  printf '%s ' ready > "$ORBX_TMP/seq"
  export ORB_STUB_STATUS_SEQ="$ORBX_TMP/seq"
  mkdir -p "$HOME/.orbx/templates"; touch "$HOME/.orbx/templates/default.yaml"
  export USER=tomasz
  cd "$PROJECT_DIR"
}

@test "run passes the command via positional args, cd'd to the target" {
  orbx_source; setup_ready_machine
  run orbx_run run bin/dev
  [ "$status" -eq 0 ]
  grep -q -- "-m korelo" "$ORB_STUB_LOG"
  grep -q -- "/home/tomasz/code/korelo" "$ORB_STUB_LOG"
  grep -q -- "bin/dev" "$ORB_STUB_LOG"
}

@test "default (no args) ensures up then opens a shell" {
  orbx_source; setup_ready_machine
  run orbx_run
  [ "$status" -eq 0 ]
  # shell invocation targets the machine
  grep -qF 'exec "$SHELL"' "$ORB_STUB_LOG"
}

@test "run forwards flags after -- verbatim" {
  orbx_source; setup_ready_machine
  run orbx_run run -- bin/rails -e production
  [ "$status" -eq 0 ]
  grep -q -- "bin/rails -e production" "$ORB_STUB_LOG"
}
