load helpers/test_helper

@test "resolves a user template from ~/.orbx/templates" {
  orbx_source
  mkdir -p "$HOME/.orbx/templates"
  touch "$HOME/.orbx/templates/default.yaml"
  run orbx::resolve_template default
  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/.orbx/templates/default.yaml" ]
}

@test "falls back to the bundled/dev templates dir" {
  orbx_source   # ORBX_BUNDLED_TEMPLATE_DIR is unstamped, so dev fallback applies
  run orbx::resolve_template default
  [ "$status" -eq 0 ]
  [[ "$output" == *"/templates/default.yaml" ]]
}

@test "user template shadows the bundled one" {
  orbx_source
  mkdir -p "$HOME/.orbx/templates"
  touch "$HOME/.orbx/templates/default.yaml"
  run orbx::resolve_template default
  [ "$output" = "$HOME/.orbx/templates/default.yaml" ]
}

@test "unknown template errors" {
  orbx_source
  run orbx::resolve_template does-not-exist
  [ "$status" -ne 0 ]
}

@test "ORBX_TEMPLATE_DIR is searched before the user dir" {
  orbx_source
  mkdir -p "$ORBX_TMP/tpl" "$HOME/.orbx/templates"
  touch "$ORBX_TMP/tpl/default.yaml" "$HOME/.orbx/templates/default.yaml"
  export ORBX_TEMPLATE_DIR="$ORBX_TMP/tpl"
  run orbx::resolve_template default
  [ "$output" = "$ORBX_TMP/tpl/default.yaml" ]
}

@test "resolves a template path relative to \$PWD" {
  orbx_source
  mkdir -p "$PROJECT_DIR/.orbx"
  touch "$PROJECT_DIR/.orbx/rails.yaml"
  cd "$PROJECT_DIR"
  run orbx::resolve_template .orbx/rails.yaml
  [ "$status" -eq 0 ]
  [ "$output" = "$PROJECT_DIR/.orbx/rails.yaml" ]
}

@test "resolves a ./-prefixed template path" {
  orbx_source
  mkdir -p "$PROJECT_DIR/tpl"
  touch "$PROJECT_DIR/tpl/custom.yaml"
  cd "$PROJECT_DIR"
  run orbx::resolve_template ./tpl/custom.yaml
  [ "$status" -eq 0 ]
  [ "$output" = "$PROJECT_DIR/tpl/custom.yaml" ]
}

@test "resolves an absolute template path" {
  orbx_source
  touch "$ORBX_TMP/abs.yaml"
  cd "$PROJECT_DIR"
  run orbx::resolve_template "$ORBX_TMP/abs.yaml"
  [ "$status" -eq 0 ]
  [ "$output" = "$ORBX_TMP/abs.yaml" ]
}

@test "expands a ~/-prefixed template path" {
  orbx_source
  mkdir -p "$HOME/mine"
  touch "$HOME/mine/tpl.yaml"
  cd "$PROJECT_DIR"
  run orbx::resolve_template '~/mine/tpl.yaml'
  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/mine/tpl.yaml" ]
}

@test "a .yml extension is treated as a path too" {
  orbx_source
  touch "$PROJECT_DIR/box.yml"
  cd "$PROJECT_DIR"
  run orbx::resolve_template box.yml
  [ "$status" -eq 0 ]
  [ "$output" = "$PROJECT_DIR/box.yml" ]
}

@test "a missing template path errors and names the path" {
  orbx_source
  cd "$PROJECT_DIR"
  run orbx::resolve_template .orbx/gone.yaml
  [ "$status" -ne 0 ]
  [[ "$output" == *"$PROJECT_DIR/.orbx/gone.yaml"* ]]
}

@test "a bare name with a slash still searches the template dirs" {
  orbx_source
  mkdir -p "$HOME/.orbx/templates/sub"
  touch "$HOME/.orbx/templates/sub/nested.yaml"
  cd "$PROJECT_DIR"
  run orbx::resolve_template sub/nested
  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/.orbx/templates/sub/nested.yaml" ]
}

@test "a committed .orbxrc template path drives orb create" {
  orbx_source
  mkdir -p "$PROJECT_DIR/.orbx"
  touch "$PROJECT_DIR/.orbx/rails.yaml"
  printf '%s\n' 'template = .orbx/rails.yaml' > "$PROJECT_DIR/.orbxrc"
  cd "$PROJECT_DIR"
  run orbx_run up --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"orb create -c $PROJECT_DIR/.orbx/rails.yaml --isolated"* ]]
}

# --- bundled default template: non-interactive hardening (issue #3) ----------
# Agents drive this template from a shell they cannot type into. A git
# credential prompt does not fail there, it hangs until the session is killed.

@test "default template disables git terminal prompts in login shells" {
  run grep -E "^\s+export GIT_TERMINAL_PROMPT=0$" \
    "$ORBX_TEST_ROOT/templates/default.yaml"
  [ "$status" -eq 0 ]
}

@test "default template disables git terminal prompts in non-login shells too" {
  # /etc/profile.d is not sourced by a bare `orb -m <name> bash -c ...`;
  # /etc/environment is. Appended, because PATH already lives in that file.
  run grep -A2 -E "^\s+- path: /etc/environment$" \
    "$ORBX_TEST_ROOT/templates/default.yaml"
  [ "$status" -eq 0 ]
  [[ "$output" == *"append: true"* ]]
  [[ "$output" != *"permissions"* ]]   # would mean a replace, wiping PATH

  run grep -E "^\s+GIT_TERMINAL_PROMPT=0$" "$ORBX_TEST_ROOT/templates/default.yaml"
  [ "$status" -eq 0 ]
}

@test "default template installs patch explicitly" {
  # git only Recommends patch; don't depend on apt keeping recommends on.
  run grep -E "^\s+- patch$" "$ORBX_TEST_ROOT/templates/default.yaml"
  [ "$status" -eq 0 ]
}

@test "default template ships the per-run inspection tools" {
  # Each of these fails confusingly rather than cleanly when absent: no `dig`
  # to check a hostname, no `lsof -i` to find what holds a port, no `sponge`
  # to rewrite a file mid-pipeline.
  for pkg in lsof bind9-dnsutils rsync zip file moreutils; do
    run grep -E "^\s+- ${pkg}$" "$ORBX_TEST_ROOT/templates/default.yaml"
    [ "$status" -eq 0 ] || { echo "missing package: $pkg"; return 1; }
  done

  # Never the bare `dnsutils`: it is virtual on 26.04, and cloud-init drops
  # names APT cannot resolve directly -- then fails the whole package stage.
  run grep -E "^\s+- dnsutils$" "$ORBX_TEST_ROOT/templates/default.yaml"
  [ "$status" -ne 0 ]
}

@test "default template gets python from mise, not apt" {
  # Ubuntu's python3 is PEP 668-marked: apt's python3-pip installs a pip that
  # refuses to install anything outside a venv. mise's precompiled Python
  # ships a pip that works.
  run grep -E "^\s+- python3-(pip|venv)$" "$ORBX_TEST_ROOT/templates/default.yaml"
  [ "$status" -ne 0 ]

  run grep -E 'mise" use -g .*python@latest' "$ORBX_TEST_ROOT/templates/default.yaml"
  [ "$status" -eq 0 ]
}

@test "default template keeps agent tooling off the ruby/node mise line" {
  # A failed shellcheck download must not take Ruby and Node down with it.
  run grep -E 'mise" use -g ruby@latest node@lts$' \
    "$ORBX_TEST_ROOT/templates/default.yaml"
  [ "$status" -eq 0 ]
}

@test "default template registers git-lfs filters, not just the binary" {
  # Installing git-lfs is not enough: until `git lfs install` writes the
  # clean/smudge filters, cloning an LFS repo silently yields pointer files.
  run grep -E 'mise" use -g .*git-lfs' "$ORBX_TEST_ROOT/templates/default.yaml"
  [ "$status" -eq 0 ]

  run grep -E 'git lfs install' "$ORBX_TEST_ROOT/templates/default.yaml"
  [ "$status" -eq 0 ]
}

@test "default template does not ask apt for postgresql-contrib" {
  # No candidate on 26.04: cloud-init drops names APT cannot resolve and then
  # fails the entire package stage. The contrib extensions ship in the server
  # package regardless.
  run grep -E "^\s+- postgresql-contrib$" "$ORBX_TEST_ROOT/templates/default.yaml"
  [ "$status" -ne 0 ]
}

# --- bundled default template: machine-level agent instructions (issue #6) ---
# Both agents read a home-directory instructions file at the start of every
# session. orbx seeds both from one source so agents stop rediscovering (or
# guessing wrong about) the machine's conventions.

@test "default template ships a single agent-instructions source" {
  run grep -cE "^\s+- path: /etc/orbx/agent-instructions\.md$" \
    "$ORBX_TEST_ROOT/templates/default.yaml"
  [ "$status" -eq 0 ]
  [ "$output" -eq 1 ]   # one source; both agent files are copies of it
}

@test "default template seeds both agents' instruction paths" {
  # Vendor-fixed lookup paths: Claude Code reads ~/.claude/CLAUDE.md, Copilot
  # CLI reads ~/.copilot/copilot-instructions.md. If either moves upstream this
  # breaks silently, so pin both.
  run grep -F '"$HOME/.claude/CLAUDE.md"' "$ORBX_TEST_ROOT/templates/default.yaml"
  [ "$status" -eq 0 ]
  run grep -F '"$HOME/.copilot/copilot-instructions.md"' \
    "$ORBX_TEST_ROOT/templates/default.yaml"
  [ "$status" -eq 0 ]
}

@test "instruction seeding is guarded on the file, not the directory" {
  # The Claude Code and Copilot installers run earlier in user-setup.sh and may
  # already have created ~/.claude and ~/.copilot; a dir check would then skip
  # the copy on a fresh machine. A file check also preserves a user's own file.
  run grep -F '[ -f "$HOME/.claude/CLAUDE.md" ]' \
    "$ORBX_TEST_ROOT/templates/default.yaml"
  [ "$status" -eq 0 ]
  run grep -F '[ -f "$HOME/.copilot/copilot-instructions.md" ]' \
    "$ORBX_TEST_ROOT/templates/default.yaml"
  [ "$status" -eq 0 ]
}

@test "default template never writes the project's AGENTS.md" {
  # That file lives in the repo mounted from the host. Writing it would dirty
  # the user's git tree and eventually get committed.
  run grep -E "(^\s+- path:.*AGENTS\.md|cp .*AGENTS\.md|> *\"?\\\$HOME.*AGENTS\.md)" \
    "$ORBX_TEST_ROOT/templates/default.yaml"
  [ "$status" -ne 0 ]
}

@test "agent instructions carry the facts an agent would otherwise misdiagnose" {
  # Not a tool inventory -- agents discover tools by running them. These are the
  # conventions whose failure mode is the agent "fixing" the machine instead.
  run grep -F 'trust auth on' "$ORBX_TEST_ROOT/templates/default.yaml"
  [ "$status" -eq 0 ]
  run grep -F 'do not assume this container has no systemd' \
    "$ORBX_TEST_ROOT/templates/default.yaml"
  [ "$status" -eq 0 ]
  run grep -F 'do not set `GIT_TERMINAL_PROMPT=1`' \
    "$ORBX_TEST_ROOT/templates/default.yaml"
  [ "$status" -eq 0 ]
}

@test "agent instructions state that project instructions win" {
  # Copilot CLI ranks personal instructions above the repo's AGENTS.md, so this
  # file must defer explicitly and stay to machine facts.
  run grep -F 'wins wherever the two could disagree' \
    "$ORBX_TEST_ROOT/templates/default.yaml"
  [ "$status" -eq 0 ]
}
