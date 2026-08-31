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

@test "up exits non-zero when provisioning fails" {
  orbx_source
  : > "$ORBX_TMP/list"
  export ORB_STUB_LIST_FIXTURE="$ORBX_TMP/list"
  printf '%s ' provisioning failed > "$ORBX_TMP/seq"
  export ORB_STUB_STATUS_SEQ="$ORBX_TMP/seq"
  mkdir -p "$HOME/.orbx/templates"; touch "$HOME/.orbx/templates/default.yaml"
  cd "$PROJECT_DIR"
  run orbx_run up
  [ "$status" -ne 0 ]
  [[ "$output" == *"orbx logs"* ]]
}

@test "wait_ready says nothing when the machine is already provisioned" {
  orbx_source
  printf '%s ' ready > "$ORBX_TMP/seq"
  export ORB_STUB_STATUS_SEQ="$ORBX_TMP/seq"
  run orbx::wait_ready korelo
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "wait_ready reports that it is waiting, then how long it took" {
  orbx_source
  printf '%s ' provisioning ready > "$ORBX_TMP/seq"
  export ORB_STUB_STATUS_SEQ="$ORBX_TMP/seq"
  run orbx::wait_ready korelo
  [ "$status" -eq 0 ]
  [[ "$output" == *"provisioning korelo"* ]]
  [[ "$output" == *"ready in"* ]]
  # No spinner escape codes when stderr is not a terminal.
  [[ "$output" != *$'\033'* ]]
}

@test "verbose streams each provisioning log line exactly once" {
  orbx_source
  printf '%s ' provisioning provisioning ready > "$ORBX_TMP/seq"
  export ORB_STUB_STATUS_SEQ="$ORBX_TMP/seq"
  printf '%s\n' "Installing mise..." "Installing Ruby (latest)..." > "$ORBX_TMP/prov.log"
  export ORB_STUB_PROVISION_LOG_FIXTURE="$ORBX_TMP/prov.log"
  ORBX_VERBOSE=1 run orbx::wait_ready korelo
  [ "$status" -eq 0 ]
  [ "$(grep -c 'Installing mise' <<< "$output")" -eq 1 ]
  [ "$(grep -c 'Installing Ruby' <<< "$output")" -eq 1 ]
}

@test "without verbose the provisioning log is not streamed" {
  orbx_source
  printf '%s ' provisioning ready > "$ORBX_TMP/seq"
  export ORB_STUB_STATUS_SEQ="$ORBX_TMP/seq"
  printf '%s\n' "Installing mise..." > "$ORBX_TMP/prov.log"
  export ORB_STUB_PROVISION_LOG_FIXTURE="$ORBX_TMP/prov.log"
  run orbx::wait_ready korelo
  [ "$status" -eq 0 ]
  [[ "$output" != *"Installing mise"* ]]
}

@test "-v is accepted as a global flag" {
  orbx_source
  orbx::parse_flags -v up
  [ "$ORBX_VERBOSE" -eq 1 ]
  [ "${ORBX_ARGS[0]}" = "up" ]
}

# A backgrounded job inherits SIGINT *ignored*, and bash cannot trap a signal
# that was ignored on entry -- so no test here can deliver a real Ctrl-C. These
# two cover the halves that are testable: the trap is armed for exactly as long
# as the wait, and the handler ends the run the way a signal should.
@test "wait_ready arms the interrupt trap while waiting and disarms it after" {
  orbx_source
  printf '%s ' provisioning ready > "$ORBX_TMP/seq"
  export ORB_STUB_STATUS_SEQ="$ORBX_TMP/seq"
  orbx::wait_tick() { trap -p INT > "$ORBX_TMP/armed"; }   # runs inside the loop
  orbx::wait_ready korelo 2>/dev/null
  grep -q "orbx::on_interrupt" "$ORBX_TMP/armed"
  trap -p INT > "$ORBX_TMP/after"                          # back in the test shell
  [ ! -s "$ORBX_TMP/after" ]
}

@test "the interrupt handler re-raises, so the run dies of the signal (130)" {
  run bash -c "source '$ORBX_BIN'; orbx::on_interrupt"
  [ "$status" -eq 130 ]
}
