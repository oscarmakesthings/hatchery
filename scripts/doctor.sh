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
  local version_flag="${4:---version}"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    fail "$label is missing. $action"
  elif ! timeout 15 "$command_name" "$version_flag" >/dev/null 2>&1; then
    fail "$label could not run successfully within 15 seconds. Check: $command_name $version_flag. $action"
  else
    pass "$label is installed and runs."
  fi
}

check_git_identity() {
  command -v git >/dev/null 2>&1 || return
  local key
  for key in user.name user.email; do
    if [[ -n "$(git config --get "$key" 2>/dev/null)" ]]; then
      pass "Git $key is configured for this repository."
    else
      warn "Git $key is unset here. Set it with git config --global $key '<value>', or configure it in each project before committing."
    fi
  done
}

check_login_path() {
  local agent
  for agent in codex hermes; do
    if env -i HOME="$HOME" USER="$(id -un)" LOGNAME="$(id -un)" \
      SHELL=/bin/bash PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
      timeout 15 /bin/bash -lc 'command -v "$1" >/dev/null 2>&1' hatchery "$agent" \
      >/dev/null 2>&1; then
      pass "$agent is available in a fresh Bash login shell."
    else
      fail "$agent is unavailable in a fresh Bash login shell. Add ~/.local/bin to PATH in your active Bash login profile, reconnect over SSH, and run: $agent --version"
    fi
  done
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
  if [[ -d "$HOME/projects" && -w "$HOME/projects" && -x "$HOME/projects" ]]; then
    pass "Workspace exists and is writable at $HOME/projects."
  elif [[ -d "$HOME/projects" ]]; then
    fail "Workspace is not writable or searchable at $HOME/projects. Check its ownership and permissions with: ls -ld ~/projects"
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
  check_command 'tmux' tmux 'Run: sudo apt-get install tmux' -V
  check_command 'Node.js (required by Hermes)' node 'Re-run make bootstrap to let the Hermes installer provide Node.js.'
  check_command 'Codex' codex 'Re-run make bootstrap.'
  check_command 'Hermes' hermes 'Re-run make bootstrap.'
  check_login_path
  check_git_identity
  check_github_auth
  check_workspace

  if (( failures > 0 )); then
    printf '\nHatchery is not ready: %d required check(s) failed.\n' "$failures"
    return 1
  fi

  printf '\nHatchery system components are ready. Resolve any warnings above.\n'
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
