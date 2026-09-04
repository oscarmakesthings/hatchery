# Hatchery

Hatchery is a reproducible remote Linux workstation for agent-assisted Git work. Version 1 configures one persistent Ubuntu 24.04 x86-64 VPS with SSH, tmux, Git, GitHub CLI, Codex, Hermes, and a `~/projects` workspace.

Hatchery does not create the VPS or manage credentials. You create the server and authenticate each tool yourself.

## Prerequisites

- An Ubuntu 24.04 LTS x86-64 VPS with a non-root sudo user
- SSH public-key access from your Mac
- `git` and `make` installed on the fresh server so you can clone and bootstrap
- Accounts or API credentials for GitHub, Codex, and your chosen Hermes model provider

See [Set up a VPS](docs/setup-vps.md) for the complete first-time procedure.

## Quick start

On the VPS:

```bash
sudo apt-get update
sudo apt-get install -y git make
git clone https://github.com/oscarmakesthings/hatchery.git ~/hatchery
cd ~/hatchery
make bootstrap
```

The bootstrap installs software but does not authenticate it. When it finishes, complete the printed manual steps:

```bash
gh auth login
codex
hermes setup
make doctor
```

## Daily usage

```bash
ssh <user>@<server>
tmux new -s codex
cd ~/projects/<repository>
codex
```

Detach without stopping the session with `Ctrl+b`, then `d`. Reconnect later with:

```bash
tmux attach -t codex
```

Use the same pattern with a session named `hermes` when running Hermes.

## Documentation

- [Set up a VPS](docs/setup-vps.md)
- [Connect from a phone](docs/phone-access.md)
- [Daily Git and agent workflow](docs/workflow.md)
- [Rebuild from scratch](docs/rebuild.md)
- [Version 1 specification](SPEC.md)
