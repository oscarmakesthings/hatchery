#!/usr/bin/env bash
set -euo pipefail

TEST_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_TMP="$(mktemp -d "${TMPDIR:-/tmp}/hatchery-tests.XXXXXX")"
TEST_TMP="$(cd "$TEST_TMP" && pwd)"
cleanup() {
  local status=$?
  (( BASH_SUBSHELL == 0 )) || return "$status"
  if (( status != 0 )); then
    tail -n 30 "$TEST_TMP"/*.log >&2
  fi
  rm -rf -- "$TEST_TMP"
  return "$status"
}
trap cleanup EXIT

assert() {
  if ! "$@"; then
    printf 'Assertion failed: %s\n' "$*" >&2
    exit 1
  fi
}

test_tmux() (
  local scenario="$1"
  export HOME="$TEST_TMP/tmux-$scenario"
  mkdir -p "$HOME"
  # shellcheck source=scripts/bootstrap.sh
  source "$TEST_ROOT/scripts/bootstrap.sh"
  case "$scenario" in
    file)
      printf 'set -g mouse off\n' > "$HOME/.tmux.conf"
      cp "$HOME/.tmux.conf" "$HOME/original"
      ;;
    symlink)
      printf 'set -g mouse off\n' > "$HOME/personal.conf"
      ln -s personal.conf "$HOME/.tmux.conf"
      ;;
    broken) ln -s missing.conf "$HOME/.tmux.conf" ;;
    directory) mkdir "$HOME/.tmux.conf" ;;
  esac
  install_tmux_config
  install_tmux_config
  case "$scenario" in
    fresh) assert test "$(readlink "$HOME/.tmux.conf")" = "$TEST_ROOT/config/tmux.conf" ;;
    file)
      assert test ! -L "$HOME/.tmux.conf"
      assert cmp "$HOME/original" "$HOME/.tmux.conf"
      ;;
    symlink)
      assert test "$(readlink "$HOME/.tmux.conf")" = personal.conf
      assert test "$(cat "$HOME/personal.conf")" = 'set -g mouse off'
      ;;
    broken) assert test "$(readlink "$HOME/.tmux.conf")" = missing.conf ;;
    directory) assert test -d "$HOME/.tmux.conf" ;;
  esac
)

test_bootstrap_repeat() (
  export HOME="$TEST_TMP/bootstrap-home"
  local fixture="$TEST_TMP/bootstrap-repo"
  mkdir -p "$HOME" "$fixture/scripts" "$fixture/config"
  cp "$TEST_ROOT/scripts/bootstrap.sh" "$fixture/scripts/"
  cp "$TEST_ROOT/config/tmux.conf" "$fixture/config/"
  printf '#!/bin/bash\nprintf "doctor\\n" >> "$HOME/calls"\n' > "$fixture/scripts/doctor.sh"
  chmod +x "$fixture/scripts/doctor.sh"
  # Source the real entry point with only host checks and external operations stubbed.
  # shellcheck source=scripts/bootstrap.sh
  source "$fixture/scripts/bootstrap.sh"
  verify_platform() { :; }
  verify_user() { :; }
  sudo() { printf 'packages\n' >> "$HOME/calls"; }
  curl() { printf 'Unexpected installer download\n' >&2; exit 1; }
  codex() { :; }
  hermes() { :; }
  node() { :; }
  main
  printf 'durable work\n' > "$HOME/projects/keep"
  main
  assert test "$(cat "$HOME/projects/keep")" = 'durable work'
  assert test "$(readlink "$HOME/.tmux.conf")" = "$fixture/config/tmux.conf"
  assert test "$(grep -c '^doctor$' "$HOME/calls")" = 2
  assert test "$(grep -c '^packages$' "$HOME/calls")" = 4
)

test_doctor() (
  local scenario="$1" tool status=0
  export HOME="$TEST_TMP/doctor-$scenario"
  local bin="$TEST_TMP/bin-$scenario"
  mkdir -p "$HOME/projects" "$bin"
  printf 'keep this configuration\n' > "$HOME/.tmux.conf"
  cp "$HOME/.tmux.conf" "$TEST_TMP/expected-$scenario"
  for tool in git gh tmux node codex hermes; do
    cat > "$bin/$tool" <<'EOF'
#!/bin/bash
case "${0##*/}:$*" in
  'git:config --get user.name'|'git:config --get user.email')
    printf 'test identity\n' ;;
  'gh:auth status') exit 1 ;;
  'tmux:-V'|'git:--version'|'gh:--version'|'node:--version'|'codex:--version'|'hermes:--version') exit 0 ;;
  *) exit 1 ;;
esac
EOF
    chmod +x "$bin/$tool"
  done
  # The timeout stub executes only the fixture commands; no host tools are on PATH.
  printf '#!/bin/bash\nshift\nexec "$@"\n' > "$bin/timeout"
  chmod +x "$bin/timeout"
  case "$scenario" in
    missing) mv "$bin/codex" "$bin/codex.disabled" ;;
    broken) printf '#!/bin/bash\nexit 1\n' > "$bin/hermes" ;;
    workspace) rmdir "$HOME/projects" ;;
  esac
  # shellcheck source=scripts/doctor.sh
  source "$TEST_ROOT/scripts/doctor.sh"
  check_platform() { :; }
  check_ssh() { :; }
  check_login_path() { :; }
  (
    export PATH="$bin"
    main
  ) > "$TEST_TMP/doctor-$scenario.log" 2>&1 || status=$?
  case "$scenario" in
    ready)
      assert test "$status" = 0
      assert grep -q 'GitHub CLI is not authenticated' "$TEST_TMP/doctor-$scenario.log"
      ;;
    missing)
      assert test "$status" = 1
      assert grep -q 'Codex is missing. Re-run make bootstrap.' "$TEST_TMP/doctor-$scenario.log"
      ;;
    broken)
      assert test "$status" = 1
      assert grep -q 'Hermes could not run successfully' "$TEST_TMP/doctor-$scenario.log"
      ;;
    workspace)
      assert test "$status" = 1
      assert grep -q 'Workspace is missing' "$TEST_TMP/doctor-$scenario.log"
      ;;
  esac
  assert cmp "$TEST_TMP/expected-$scenario" "$HOME/.tmux.conf"
  assert test "$(find "$HOME" -type f | wc -l | tr -d ' ')" = 1
)

for scenario in fresh file symlink broken directory; do
  test_tmux "$scenario" > "$TEST_TMP/tmux-$scenario.log" 2>&1
  printf 'PASS: tmux configuration (%s), including repeat run\n' "$scenario"
done
test_bootstrap_repeat > "$TEST_TMP/bootstrap.log" 2>&1
printf 'PASS: repeated bootstrap preserves workspace and invokes doctor\n'
for scenario in ready missing broken workspace; do
  test_doctor "$scenario"
  printf 'PASS: doctor (%s), exit status and configuration preservation\n' "$scenario"
done
