load helpers/test_helper

# These exercise ORBX_TERM_PRELUDE — the guest-side snippet that makes the host
# terminal usable inside the VM. We run it locally under `bash -c` with fake
# infocmp/tic on PATH, so we test the branching logic without a real VM.
# ($1 = the host's `infocmp -x $TERM` output; the prelude shifts it off.)

fake_bin() {              # fake_bin NAME BODY  -> puts an executable on PATH
  local dir="$ORBX_TMP/fakebin"
  mkdir -p "$dir"
  printf '#!/usr/bin/env bash\n%s\n' "$2" > "$dir/$1"
  chmod +x "$dir/$1"
  PATH="$dir:$PATH"
}

@test "prelude keeps a VM-known TERM untouched and never seeds" {
  orbx_source
  fake_bin infocmp 'exit 0'                          # every TERM is known
  fake_bin tic 'cat >/dev/null; echo TIC_RAN'
  run env PATH="$PATH" TERM=xterm-256color \
      bash -c "$ORBX_TERM_PRELUDE"'printf T=%s "$TERM"' _ "data"
  [ "$status" -eq 0 ]
  [ "$output" = "T=xterm-256color" ]
}

@test "prelude seeds the host terminfo then keeps the original TERM" {
  orbx_source
  # infocmp reports "unknown" until tic drops the marker (simulating install).
  fake_bin infocmp "[[ -f '$ORBX_TMP/seeded' ]]"
  fake_bin tic "cat >/dev/null; : > '$ORBX_TMP/seeded'"
  run env PATH="$PATH" TERM=xterm-ghostty \
      bash -c "$ORBX_TERM_PRELUDE"'printf T=%s "$TERM"' _ "GHOSTTY-DATA"
  [ "$status" -eq 0 ]
  [ "$output" = "T=xterm-ghostty" ]
}

@test "prelude downgrades to xterm-256color when TERM is unknown and tic fails" {
  orbx_source
  fake_bin infocmp 'exit 1'                          # never known
  fake_bin tic 'cat >/dev/null; exit 1'              # seeding fails
  run env PATH="$PATH" TERM=xterm-ghostty \
      bash -c "$ORBX_TERM_PRELUDE"'printf T=%s "$TERM"' _ "somedata"
  [ "$status" -eq 0 ]
  [ "$output" = "T=xterm-256color" ]
}

@test "prelude downgrades when there is no host terminfo to seed" {
  orbx_source
  fake_bin infocmp 'exit 1'                          # unknown TERM
  fake_bin tic 'cat >/dev/null; exit 0'              # would succeed, but ti is empty
  run env PATH="$PATH" TERM=xterm-ghostty \
      bash -c "$ORBX_TERM_PRELUDE"'printf T=%s "$TERM"' _ ""
  [ "$status" -eq 0 ]
  [ "$output" = "T=xterm-256color" ]
}
