# Hatchery v1 Specification

**Status:** Proposed v1.0  
**Purpose:** Define the smallest useful version of Hatchery: a reproducible remote Linux workstation for coding agents.

## Product

Hatchery v1 is one persistent Ubuntu VPS that can be accessed from a Mac or phone over SSH.

It provides:

- SSH remote access
- tmux for persistent terminal sessions
- Git and GitHub CLI
- Codex
- Hermes
- a standard `~/projects` workspace
- a bootstrap script
- a read-only diagnostic script
- setup, usage, phone-access, and rebuild documentation

```text
Mac / Phone
     |
     | SSH
     v
+----------------+
|    Hatchery    |
| Ubuntu VPS     |
|                |
| tmux           |
| Git + gh       |
| Codex          |
| Hermes         |
+-------+--------+
        |
        v
      GitHub
```

## Goal

Hatchery v1 is complete when a fresh supported VPS can be configured, used for agent-assisted Git work, disconnected from safely, and rebuilt from scratch using only this repository and its documentation.

## Supported Environment

Server:

- Ubuntu 24.04 LTS
- x86-64
- no desktop environment

Clients:

- macOS terminal
- Termius on iPhone

Remote access:

- SSH

Session persistence:

- tmux

Source control:

- Git
- GitHub CLI

Agents:

- Codex
- Hermes

## Non-Goals

Do not implement these in v1:

- Ansible
- OpenTofu or Terraform
- Docker project environments
- disposable workers
- worker pools
- job queues
- Hatchery CLI
- web dashboard
- API
- Codex plugin or personal skill marketplace
- Tailscale
- automatic VPS provisioning
- multi-provider support
- Kubernetes
- MCP servers
- local model hosting
- handheld software or hardware integration

Do not create placeholder frameworks for future versions.

## Repository Layout

```text
hatchery/
├── README.md
├── SPEC.md
├── AGENTS.md
├── Makefile
├── .gitignore
├── scripts/
│   ├── bootstrap.sh
│   └── doctor.sh
├── config/
│   └── tmux.conf
└── docs/
    ├── setup-vps.md
    ├── phone-access.md
    ├── workflow.md
    └── rebuild.md
```

Do not add files or directories that are not needed for v1.

## Workspace

Hatchery must create:

```text
~/projects/
```

Independent Git repositories live inside that directory.

## Make Commands

The Makefile must expose only:

```text
make help
make bootstrap
make doctor
make validate
```

### `make help`

Print available commands and short descriptions.

### `make bootstrap`

Run `scripts/bootstrap.sh`.

### `make doctor`

Run `scripts/doctor.sh`.

### `make validate`

Validate the Hatchery repository itself.

At minimum:

- run shell syntax checks on shell scripts
- run ShellCheck if ShellCheck is installed

Validation must not modify the machine.

## Bootstrap Contract

`scripts/bootstrap.sh` configures an already-created Ubuntu 24.04 VPS.

It must:

1. use `set -euo pipefail`
2. verify Ubuntu 24.04
3. update package metadata
4. install or verify required system packages
5. install or verify Git
6. install or verify tmux
7. install or verify GitHub CLI
8. install or verify Node.js if required for Codex
9. install or verify Codex
10. install or verify Hermes
11. create `~/projects`
12. install Hatchery's tmux config without silently destroying unrelated user configuration
13. avoid automatic authentication
14. run `doctor.sh` at the end
15. print remaining manual authentication steps

Bootstrap does not create the VPS.

Bootstrap must be safe to run more than once.

## Authentication and Secrets

Hatchery does not manage credentials.

Bootstrap must not automatically authenticate GitHub, Codex, or Hermes.

Secrets, tokens, SSH private keys, passwords, and populated `.env` files must never be committed.

## Doctor Contract

`scripts/doctor.sh` is read-only.

It must never:

- install packages
- modify configuration
- authenticate
- restart services
- delete files
- create infrastructure

It should check:

- supported OS
- SSH availability
- Git
- GitHub CLI
- tmux
- Node.js when required
- Codex
- Hermes
- GitHub authentication when safely detectable
- `~/projects`

It must return a nonzero exit code when a required component is missing.

Failures should include a useful next action.

## tmux Configuration

`config/tmux.conf` must stay minimal.

Allowed improvements:

- mouse support
- larger scrollback history
- simple status information
- sensible terminal behavior

Required workflow:

```bash
tmux new -s codex
# run Codex
# detach with Ctrl+b d

tmux attach -t codex
```

The same pattern must work for Hermes.

## Git Workflow

Hatchery uses normal Git commands.

```text
SSH into Hatchery
        |
attach tmux
        |
cd ~/projects/<repo>
        |
create or switch branch
        |
Codex or Hermes work
        |
run project checks
        |
review git diff
        |
commit
        |
push branch
        |
open GitHub PR
```

Agents should not push directly to `main` unless explicitly instructed.

## Phone Access

`docs/phone-access.md` must document:

- adding the Hatchery host in Termius
- SSH key authentication
- connecting
- listing tmux sessions
- attaching
- detaching
- reconnecting after network interruption

## Documentation Requirements

### `README.md`

Explain:

- what Hatchery is
- what v1 does
- prerequisites
- quick start
- daily workflow
- links to detailed docs

### `docs/setup-vps.md`

Document manual VPS creation and first SSH connection.

### `docs/workflow.md`

Document the normal Mac/phone -> SSH -> tmux -> agent -> GitHub workflow.

### `docs/rebuild.md`

Document rebuilding Hatchery from a fresh VPS using only the repository.

## AGENTS.md Requirements

`AGENTS.md` must instruct coding agents to:

- read `SPEC.md` before architectural changes
- keep implementations small
- prefer standard Linux tools
- avoid v1 non-goals
- never commit secrets
- preserve unrelated user configuration
- avoid destructive actions without explicit approval
- run `make validate` before finishing
- review the final Git diff

## Rebuild Test

Before v1 is complete:

1. configure a working Hatchery VPS
2. destroy it
3. create a fresh Ubuntu 24.04 VPS manually
4. clone Hatchery
5. run `make bootstrap`
6. complete documented authentication
7. clone a test project
8. start Codex or Hermes inside tmux
9. disconnect SSH
10. reconnect and reattach
11. make a Git change
12. push the branch successfully

Fix any missing documentation or setup steps discovered during the rebuild.

## Acceptance Criteria

Hatchery v1 is complete when:

1. a clean Ubuntu 24.04 VPS can clone Hatchery
2. `make bootstrap` completes successfully
3. `make doctor` accurately reports readiness
4. Git can clone, commit, and push
5. GitHub CLI works after manual authentication
6. Codex runs successfully
7. Hermes runs successfully
8. tmux sessions survive SSH disconnects
9. Mac SSH access works
10. Termius SSH access works
11. no credentials are stored in the repository
12. the VPS has been destroyed and rebuilt successfully once
