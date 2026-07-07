# orbx

`orbx` = **Orb**stack linu**X** — a zero-dependency Bash CLI that spins up a
per-project, isolated [OrbStack](https://orbstack.dev) machine. It derives the
machine name from the current folder, mounts `$PWD` into it at the matching
path, provisions it from a template (a cloud-init file), waits until it's
ready, and drops you into a shell.

The tool is template-agnostic: the bundled `default` template is a Rails +
Claude Code sandbox, but naming, mounting, lifecycle, and `--dry-run` work with
any cloud-init template you point it at.

## Install

```sh
brew install defkode/tap/orbx
```

## Everyday flow

```sh
cd ~/code/myapp
orbx                # creates (or starts) myapp's sandbox, waits for it to be
                     # ready, and drops you into a shell — $PWD is mounted in
```

Run it again later and it just starts the existing machine and shells in —
provisioning only happens once.

## Commands

The output of `orbx --help`:

```
orbx — per-project OrbStack Rails + Claude Code sandboxes

USAGE
  orbx [command] [flags]

COMMANDS
  (none)        Bring this project's sandbox up (create if needed) and shell in
  up            Create/start + provision, wait until ready — don't shell in
  shell         Open a shell in the sandbox
  run <cmd…>    Run a command inside (flags need --: orbx run -- bin/rails -e prod)
  status        Show state, provisioning status, template, and mount
  logs          Tail the provisioning log
  stop          Stop the machine (keeps data)
  down          Delete this sandbox permanently (asks first; --yes to skip)
  list          List all machines + status
  ip            Print this sandbox's IP
  templates     List available templates
  config        Show the effective config
  init          Scaffold ./.orbxrc in this project (--force to overwrite)

FLAGS
  --name <name>   Machine name (default: current folder, sanitized)
  --mount <spec>  Extra host:target mount (repeatable)
  --no-mount      Disable the automatic $PWD mount
  --template <n>  Template name (default: from config, else "default")
  --image <ref>   Base image (default: ubuntu:26.04)
  --arch <arch>   amd64 | arm64 (default: native)
  --dry-run       Print the orb command that would run, then exit
  --yes, -y       Assume yes for confirmations
  --force         Overwrite when scaffolding (orbx init)
  -h, --help      Show this help
  --version       Show version
```

A subcommand's own flags that start with `-` need a `--` separator, e.g.
`orbx run -- bin/rails -e production`.

## Configuration

Two flat `key = value` files, layered with CLI flags and built-in defaults.
Most specific wins:

```
CLI flags  >  ./.orbxrc (per-project, committed)  >  ~/.orbx/config  >  defaults
```

Keys: `template`, `image`, `arch`, `mount`, `name`. Lines starting with `#` and
blank lines are ignored; trailing `# comments` after a value are stripped.
Config is parsed manually (never `source`d or `eval`'d), so a config file can
never execute code.

**Global — `~/.orbx/config`:**

```
template = default
image    = ubuntu:26.04
arch     =              # blank = native; or amd64 for prod parity
mount    = true         # auto-mount $PWD
```

**Project — `./.orbxrc`** (committed, travels with the repo):

```
template = default
# image  = ubuntu:26.04
# name   = my-machine    # default: the sanitized folder name
# mount  = false         # set false to skip auto-mounting $PWD
```

Run `orbx init` to scaffold a starter `./.orbxrc` (`--force` to overwrite), and
`orbx config` to see the effective, layered config.

## Templates

Templates are cloud-init files resolved by name. `orbx` looks in, in order:
`~/.orbx/templates/<name>.yaml` (yours), then the bundled templates that ship
with the tool. A user template of the same name shadows the bundled one — so
dropping `~/.orbx/templates/default.yaml` customizes the default without
forking `orbx`. Run `orbx templates` to see what's available and which one a
project resolves to.

## Requirements

- [OrbStack](https://orbstack.dev) installed, with `orb` on `PATH`.
- Bash >= 4 (macOS ships 3.2; `brew install bash` if needed — `orbx` checks
  and prints guidance if it's too old).
