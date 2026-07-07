# Common setup for orbx bats tests.
# Usage in a .bats file:  load helpers/test_helper

setup() {
  ORBX_TEST_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  ORBX_BIN="$ORBX_TEST_ROOT/bin/orbx"

  # Isolated HOME and a shimmed PATH where our stub answers as `orb`.
  ORBX_TMP="$(mktemp -d)"
  export HOME="$ORBX_TMP/home"
  mkdir -p "$HOME"
  local shimbin="$ORBX_TMP/bin"
  mkdir -p "$shimbin"
  cp "$ORBX_TEST_ROOT/test/helpers/orb-stub" "$shimbin/orb"
  chmod +x "$shimbin/orb"
  export PATH="$shimbin:$PATH"

  export ORB_STUB_LOG="$ORBX_TMP/orb.log"
  : > "$ORB_STUB_LOG"

  # Make waits instant in tests.
  export ORBX_POLL_DELAY=0 ORBX_POLL_INTERVAL=0 ORBX_READY_TIMEOUT=5
  export ORBX_GLOBAL_CONFIG="$HOME/.orbx/config"

  # Deterministic machine user (some environments leave USER unset under set -u).
  export USER="${USER:-$(id -un)}"

  # A stable working directory under the fake HOME.
  export PROJECT_DIR="$HOME/code/korelo"
  mkdir -p "$PROJECT_DIR"
}

teardown() {
  rm -rf "$ORBX_TMP"
}

# Source bin/orbx into the current shell to unit-test its functions.
orbx_source() { source "$ORBX_BIN"; }

# Run the orbx executable (integration path).
orbx_run() { "$ORBX_BIN" "$@"; }
