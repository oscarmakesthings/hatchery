#!/usr/bin/env bash
set -uo pipefail

failures=0

pass() {
  printf '[PASS] %s\n' "$*"
}

warn() {
  printf '[WARN] %s\n' "$*"
}

fail() {
  printf '[FAIL] %s\n' "$*"
  failures=$((failures + 1))
}

check_platform() {
  if [[ ! -r /etc/os-release ]]; then
    fail 'Operating system cannot be identified. Use Ubuntu 24.04 LTS x86-64.'
    return
  fi

  # shellcheck disable=SC1091
  . /etc/os-release
  if [[ "${ID:-}" == 'ubuntu' && "${VERSION_ID:-}" == '24.04' ]]; then
    pass 'Operating system is Ubuntu 24.04 LTS.'
  else
    fail "Operating system is ${PRETTY_NAME:-unknown}; rebuild with Ubuntu 24.04 LTS."
  fi

  if [[ "$(uname -m)" == 'x86_64' ]]; then
    pass 'Architecture is x86-64.'
  else
    fail "Architecture is $(uname -m); rebuild with an x86-64 VPS."
  fi
}

check_ssh() {
  if ! command -v sshd >/dev/null 2>&1; then
    fail 'OpenSSH server is missing. Run: sudo apt-get install openssh-server'
    return
  fi

  if [[ -n "${SSH_CONNECTION:-}" ]]; then
    pass 'SSH server is available (this shell is connected over SSH).'
  elif command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet ssh; then
    pass 'SSH server is installed and active.'
  elif command -v pgrep >/dev/null 2>&1 && pgrep -x sshd >/dev/null 2>&1; then
    pass 'SSH server is installed and running.'
  else
    fail 'OpenSSH server is installed but not running. Run: sudo systemctl enable --now ssh'
  fi
}

check_command() {
  local label="$1"
  local command_name="$2"
  local action="$3"

  if command -v "$command_name" >/dev/null 2>&1; then
    pass "$label is installed."
  else
    fail "$label is missing. $action"
  fi
}

check_github_auth() {
  if ! command -v gh >/dev/null 2>&1; then
    return
  fi

  if gh auth status >/dev/null 2>&1; then
    pass 'GitHub CLI is authenticated.'
  else
    warn 'GitHub CLI is not authenticated. Run: gh auth login'
  fi
}

check_workspace() {
  if [[ -d "$HOME/projects" ]]; then
    pass "Workspace exists at $HOME/projects."
  else
    fail "Workspace is missing. Run: mkdir -p \"$HOME/projects\""
  fi
}

main() {
  export PATH="$HOME/.local/bin:$PATH"

  check_platform
  check_ssh
  check_command 'Git' git 'Run: sudo apt-get install git'
  check_command 'GitHub CLI' gh 'Run: sudo apt-get install gh'
  check_command 'tmux' tmux 'Run: sudo apt-get install tmux'
  check_command 'Node.js (required by Hermes)' node 'Re-run make bootstrap to let the Hermes installer provide Node.js.'
  check_command 'Codex' codex 'Re-run make bootstrap.'
  check_command 'Hermes' hermes 'Re-run make bootstrap.'
  check_github_auth
  check_workspace

  if (( failures > 0 )); then
    printf '\nHatchery is not ready: %d required check(s) failed.\n' "$failures"
    return 1
  fi

  printf '\nHatchery system components are ready. Resolve any warnings above.\n'
}

main "$@"
