# Set up a Hatchery VPS

Hatchery configures an existing server. It does not create or secure a cloud account for you.

## 1. Create the server

In your VPS provider's console, create one server with:

- Ubuntu 24.04 LTS
- x86-64 architecture
- a public IPv4 or IPv6 address reachable from your clients
- a non-root user with sudo access
- your Mac's SSH public key added during creation

Do not paste private keys, access tokens, or passwords into this repository.

If you do not already have an SSH key on the Mac, create one and display its public half:

```bash
ssh-keygen -t ed25519 -C "hatchery"
cat ~/.ssh/id_ed25519.pub
```

Give only the `.pub` value to the VPS provider. Keep the private key on your devices.

## 2. Make the first connection

From the Mac, replace the placeholders with the server values:

```bash
ssh <user>@<server>
```

Confirm that the account is not root and can use sudo:

```bash
whoami
sudo -v
```

## 3. Clone and bootstrap Hatchery

A minimal Ubuntu image may not include the two commands needed to fetch and start Hatchery, so install those first:

```bash
sudo apt-get update
sudo apt-get install -y git make
git clone https://github.com/oscarmakesthings/hatchery.git ~/hatchery
cd ~/hatchery
make bootstrap
```

Bootstrap verifies Ubuntu 24.04 x86-64, installs the system tools, installs Codex and Hermes for the current user, and creates `~/projects`. It links `~/.tmux.conf` to Hatchery's minimal config only when that path is absent. Existing files, directories, and symlinks (including broken links) are left untouched, so your current settings stay active.

To opt into Hatchery defaults with an existing configuration, add this line near the beginning of your tmux configuration, before your personal overrides:

```tmux
source-file ~/hatchery/config/tmux.conf
```

Adjust the path if you cloned Hatchery elsewhere. Review the defaults before including them. tmux loads the configuration when its server starts; to apply it to a running server, run `tmux source-file ~/.tmux.conf`. Keep the Hatchery checkout available while your configuration links to or sources it.

Codex uses the [official standalone installer](https://learn.chatgpt.com/docs/codex/cli). Hermes uses the [official command-line installer](https://hermes-agent.nousresearch.com/docs/getting-started/installation); Hatchery skips its setup wizard and optional browser/computer-use downloads.

## 4. Authenticate manually

Bootstrap never authenticates tools or asks for tokens. Run each step yourself:

```bash
gh auth login
codex
hermes setup
```

- In `gh auth login`, select GitHub.com, choose HTTPS or SSH for Git operations, and follow the browser or token flow.
- On the first `codex` launch, choose a supported sign-in method, then exit when sign-in is confirmed.
- In `hermes setup`, choose your model provider and supply credentials directly to Hermes when prompted.

Credentials belong in each tool's user-level configuration, never inside `~/hatchery` or a project repository.

## 5. Verify readiness

```bash
cd ~/hatchery
make doctor
```

Doctor is read-only. Fix any failed required check using the action it prints. An authentication warning means the software is installed but its manual sign-in is incomplete.

Doctor also runs bounded version checks, checks workspace permissions and Git author configuration, and checks agent discovery in a fresh Bash login shell with a clean environment. The login-shell check assumes the Ubuntu user's shell is Bash; it does not open a new SSH connection. Confirm access after bootstrap by disconnecting, reconnecting, and running `codex --version` and `hermes --version` yourself.

If the login-shell check fails, ensure your active Bash login profile adds the agent installation directory to PATH:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Bash reads the first available file of `~/.bash_profile`, `~/.bash_login`, and `~/.profile`. Add the line to that file without replacing its existing contents, then reconnect. Bootstrap's temporary PATH changes do not update your current SSH shell.

Before committing, configure your Git author name and email with `git config --global user.name '<name>'` and `git config --global user.email '<email>'`, or set them separately inside each project. Doctor reports missing author settings as warnings because project-specific settings may be intentional.
