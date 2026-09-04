# Rebuild Hatchery

A rebuild proves that the repository and documentation are sufficient to recreate the workstation. Back up or push every project change you need before destroying a server.

## 1. Preserve durable work

On the old VPS, inspect every repository under `~/projects`:

```bash
find ~/projects -mindepth 1 -maxdepth 1 -type d -print
```

For each repository, run `git status`, commit the work that should survive, and push its branch. Files not committed and pushed will not be restored by Hatchery. Record any provider-specific server address or DNS changes needed for the replacement.

Do not copy tool credentials into this repository. Plan to authenticate again on the new server.

## 2. Replace the VPS manually

Destroy the old VPS only after confirming its needed work exists elsewhere. In the provider console, create a fresh Ubuntu 24.04 LTS x86-64 VPS with a non-root sudo user and your SSH public key, following [Set up a VPS](setup-vps.md).

Connect to its new address:

```bash
ssh <user>@<new-server>
```

## 3. Restore Hatchery

```bash
sudo apt-get update
sudo apt-get install -y git make
git clone https://github.com/oscarmakesthings/hatchery.git ~/hatchery
cd ~/hatchery
make bootstrap
```

Authenticate each tool manually:

```bash
gh auth login
codex
hermes setup
make doctor
```

## 4. Restore project workflow

Clone a project and prove the persistent-session and Git path end to end:

```bash
cd ~/projects
git clone <test-repository-url>
cd <test-repository>
git switch -c hatchery-rebuild-test
tmux new -s codex
codex
```

Make a harmless test change, run the project's checks, review the diff, commit it, and push the branch. Detach with `Ctrl+b`, then `d`; disconnect SSH; reconnect; and run:

```bash
tmux attach -t codex
```

The rebuild is verified only after the session survives reconnection and the test branch pushes successfully. Delete or close the test branch through the normal repository workflow when it is no longer needed.
