# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`orbx` (**Orb**stack linu**X**) is a single-file, zero-dependency Bash CLI that
spins up per-project [OrbStack](https://orbstack.dev) Linux machines. It derives
a machine name from `$PWD`, mounts the project into the VM, provisions it from a
cloud-init template, waits for readiness, and shells in. All product code lives
in one script: `bin/orbx`.

## Commands

```sh
bats test/                              # run all tests
bats test/shellrun.bats                 # run one file
bats -f "run forwards flags" test/      # run tests matching a name

shellcheck bin/orbx test/helpers/orb-stub script/release   # lint (CI pins v0.11.0)

script/release X.Y.Z                    # cut a release (see below)
```

There is no build step — `bin/orbx` is the shipped artifact.

## Architecture

**Dual-mode script.** `bin/orbx` runs as an executable *or* is `source`d. The
guard at the bottom (`if [[ "${BASH_SOURCE[0]}" == "${0}" ]]`) means `main`
runs only when executed; when sourced, only the `orbx::*` functions load. Tests
rely on this: `orbx_source` (unit-test individual functions) vs `orbx_run`
(integration through `main`). `set -euo pipefail` is set inside that guard, so
it does *not* apply when sourced.

**Config layering.** Precedence, most-specific wins:
`CLI flags > ./.orbxrc > ~/.orbx/config > built-in defaults`.
`orbx::effective_config` merges the two flat `key = value` files over defaults;
`orbx::resolve_context` then re-reads that plus the parsed `ORBX_FLAG_*` vars and
populates the `ORBX_*` run-state globals every command reads. Config is parsed
line-by-line (`orbx::parse_config_file`) and **never `source`d or `eval`'d** — a
config file can't execute code. Keep it that way. Values can't contain `#`
(everything after `#` is a comment).

**Template resolution.** Templates are cloud-init YAML resolved by name through a
search path (`orbx::resolve_template`): `$ORBX_TEMPLATE_DIR` → `~/.orbx/templates`
→ bundled dir → `<script>/../templates`. A user file shadows the bundled one of
the same name. `ORBX_BUNDLED_TEMPLATE_DIR` is the literal `@TEMPLATE_DIR@`
placeholder in-repo; the Homebrew formula rewrites it at install time (unstamped
in a git checkout, which is why the `<script>/../templates` fallback exists).

**Machine lifecycle** wraps the `orb` CLI. `ensure_up` creates (via the assembled
`ORBX_CREATE_CMD` = `orb create -c <template> --isolated ...`) or starts the
machine, then `wait_ready` polls `orb -m <name> -u root cat /etc/sandbox-status`
until it reads `ready` (or `failed`/timeout). Readiness is driven by the
template writing that file — the CLI and the template share this contract.

**Terminfo prelude.** `ORBX_TERM_PRELUDE` is a guest-side bash snippet prepended
to every `shell`/`run` invocation. The host's `infocmp -x $TERM`
(`orbx::host_terminfo`) is passed as a positional arg; the guest seeds its own
terminfo (`tic`) or falls back to `xterm-256color`, so terminals like Ghostty/
WezTerm/kitty get working line editing. `$1`/`$SHELL`/`$@` in these strings must
expand **in the VM**, not locally — hence the `# shellcheck disable=SC2016`
markers. Don't "fix" those.

## Testing conventions

Tests are [bats](https://github.com/bats-core/bats-core). `test/helpers/orb-stub`
is a fake `orb`: it appends its full argv to `$ORB_STUB_LOG` (assertions grep
this log) and emits scripted output from fixtures pointed to by env vars
(`ORB_STUB_LIST_FIXTURE`, `ORB_STUB_STATUS_SEQ`, `ORB_STUB_INFO_FIXTURE`, …).
`test_helper.bash` gives each test an isolated `$HOME`, a PATH-shimmed `orb`, and
zeroed poll timers (`ORBX_POLL_DELAY/INTERVAL`, `ORBX_READY_TIMEOUT`) so waits are
instant. The stub is shellcheck-linted alongside the CLI, so keep it clean.

## Release flow

`script/release X.Y.Z` requires a clean tree on `main`, runs shellcheck + bats,
bumps `ORBX_VERSION` in `bin/orbx` and the version string in `test/cli.bats`
(re-running bats after), then commits, tags `vX.Y.Z`, and pushes. The tag push
triggers `.github/workflows/release.yml`, which creates the GitHub release and
bumps the Homebrew formula in the **separate** `defkode/homebrew-tap` repo (needs
the `TAP_TOKEN` secret). Bumping the version means editing it in **both**
`bin/orbx` and `test/cli.bats` — the release script does this for you.

## Conventions

- All functions are namespaced `orbx::`. Errors go through `orbx::die` (message to
  stderr, exit 1).
- Requires bash >= 4; the top-of-file guard is POSIX-compatible so it can reject
  macOS's stock bash 3.2 *before* any bash-4 syntax (`declare -g/-A`) is parsed.
- Subcommand flags starting with `-` need a `--` separator, e.g.
  `orbx run -- bin/rails -e production` (see `orbx::parse_flags`).
- `--dry-run` prints the `orb create` command and exits — use it to inspect
  behavior without touching OrbStack.
