#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
TMUX_SOURCE="$REPO_DIR/config/tmux.conf"
TMUX_TARGET="$HOME/.tmux.conf"
readonly SCRIPT_DIR REPO_DIR TMUX_SOURCE TMUX_TARGET

log() {
  printf '[hatchery] %s\n' "$*"
}

die() {
  printf '[hatchery] ERROR: %s\n' "$*" >&2
  exit 1
}

verify_platform() {
  [[ -r /etc/os-release ]] || die 'Cannot read /etc/os-release; Ubuntu 24.04 is required.'

  # shellcheck disable=SC1091
  . /etc/os-release
  [[ "${ID:-}" == 'ubuntu' && "${VERSION_ID:-}" == '24.04' ]] ||
    die "Unsupported operating system: ${PRETTY_NAME:-unknown}. Ubuntu 24.04 LTS is required."
  [[ "$(uname -m)" == 'x86_64' ]] ||
    die "Unsupported architecture: $(uname -m). x86-64 is required."
}

verify_user() {
  (( EUID != 0 )) || die 'Run bootstrap as a normal sudo-capable user, not as root.'
  command -v sudo >/dev/null 2>&1 || die 'sudo is required for system package installation.'
  log 'Checking sudo access.'
  sudo -v
}

install_packages() {
  local -a packages=(
    ca-certificates
    curl
    gh
    git
    make
    openssh-server
    tmux
    xz-utils
  )

  log 'Updating apt package metadata.'
  sudo DEBIAN_FRONTEND=noninteractive apt-get update
  log 'Installing required system packages.'
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}"
}

install_codex() {
  if command -v codex >/dev/null 2>&1; then
    log 'Codex is already installed.'
    return
  fi

  log 'Installing Codex with the official standalone installer.'
  curl -fsSL https://chatgpt.com/codex/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
  command -v codex >/dev/null 2>&1 ||
    die 'Codex installation finished, but codex is not available in ~/.local/bin or PATH.'
}

install_hermes() {
  if command -v hermes >/dev/null 2>&1 && command -v node >/dev/null 2>&1; then
    log 'Hermes and its Node.js dependency are already installed.'
    return
  fi

  log 'Installing Hermes without authentication or optional browser/computer-use components.'
  curl -fsSL https://hermes-agent.nousresearch.com/install.sh |
    bash -s -- --skip-setup --skip-browser --skip-computer-use
  export PATH="$HOME/.local/bin:$PATH"
  command -v hermes >/dev/null 2>&1 ||
    die 'Hermes installation finished, but hermes is not available in ~/.local/bin or PATH.'
}

install_tmux_config() {
  if [[ -L "$TMUX_TARGET" && "$(readlink -- "$TMUX_TARGET")" == "$TMUX_SOURCE" ]]; then
    log 'Hatchery tmux configuration is already installed.'
    return
  fi

  if [[ -e "$TMUX_TARGET" || -L "$TMUX_TARGET" ]]; then
    log "Preserving existing tmux configuration at $TMUX_TARGET"
    log 'To opt into Hatchery defaults, see docs/setup-vps.md; existing settings remain active.'
    return
  fi

  ln -s -- "$TMUX_SOURCE" "$TMUX_TARGET"
  log "Installed Hatchery tmux configuration at $TMUX_TARGET"
}

print_manual_steps() {
  cat <<'EOF'

[hatchery] Software installation is complete.
[hatchery] Authentication is intentionally manual. Run:
  gh auth login
  codex          # choose a sign-in method on first launch
  hermes setup   # choose and authenticate a model provider
  make doctor    # re-check readiness afterward
EOF
}

main() {
  verify_platform
  verify_user
  install_packages

  export PATH="$HOME/.local/bin:$PATH"
  install_codex
  install_hermes

  mkdir -p -- "$HOME/projects"
  log "Workspace ready at $HOME/projects"
  install_tmux_config
  print_manual_steps

  "$SCRIPT_DIR/doctor.sh"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
