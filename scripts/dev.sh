#!/usr/bin/env bash
# HarmonyOS dev helper: build / install / run / inspect from the terminal.
# Prefers DevEco CLI (devecocli) when installed, falls back to raw hvigorw/hdc.
#
# Usage: bash scripts/dev.sh <command> [args...]
# Run `bash scripts/dev.sh help` for the command list.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [ -f "$ROOT/scripts/env.sh" ]; then
  # shellcheck disable=SC1091
  . "$ROOT/scripts/env.sh" >/dev/null 2>&1 || true
fi

ARTIFACTS="$ROOT/artifacts"
TARGET_ARGS=()
if [ -n "${HDOS_TARGET:-}" ]; then
  TARGET_ARGS=(-t "$HDOS_TARGET")
fi

have() { command -v "$1" >/dev/null 2>&1; }

hdc_() {
  if [ ${#TARGET_ARGS[@]} -gt 0 ]; then
    hdc "${TARGET_ARGS[@]}" "$@"
  else
    hdc "$@"
  fi
}

# --- hdc hardening ---------------------------------------------------------
# A wedged hdc session does not report an error. The command IS sent to the
# device daemon; the reply just never arrives. Because a session's work channel
# is serialised, every later shell/file command queues behind it and ends in
# EOF, while the control path keeps working -- so `hdc list targets` goes on
# answering "Connected" the whole time and nothing downstream notices. Log
# evidence (heartbeats still flowing both ways while the work counter is
# frozen) and the full story: docs/toolchain/03-踩过的坑.md 「坑 1」, raw logs in /tmp/hdc-*.log.
#
# Hence two rules, implemented here:
#   1. no short-lived hdc command runs without a timeout;
#   2. no hdc exit code is trusted -- verify with a real shell round-trip.
#      Exit codes genuinely lie: bare `hdc reconnect` (no target key) prints
#      "[Fail]Usage: reconnect <target-key>" and still exits 0.
HDOS_HDC_TIMEOUT="${HDOS_HDC_TIMEOUT:-60}"              # seconds; 0 disables
HDOS_HDC_INSTALL_TIMEOUT="${HDOS_HDC_INSTALL_TIMEOUT:-900}"
HDOS_HDC_WAIT="${HDOS_HDC_WAIT:-15}"                   # health poll budget, s
case "$HDOS_HDC_TIMEOUT" in ''|*[!0-9]*) HDOS_HDC_TIMEOUT=60 ;; esac
case "$HDOS_HDC_INSTALL_TIMEOUT" in ''|*[!0-9]*) HDOS_HDC_INSTALL_TIMEOUT=900 ;; esac
case "$HDOS_HDC_WAIT" in ''|*[!0-9]*) HDOS_HDC_WAIT=15 ;; esac
HDC_PROBE_MARK="hdc-probe-ok"

hdc_t() {  # hdc with a timeout, target args preserved
  local t="$1"; shift
  if [ ${#TARGET_ARGS[@]} -gt 0 ]; then
    timeout "$t" hdc "${TARGET_ARGS[@]}" "$@"
  else
    timeout "$t" hdc "$@"
  fi
}

hdc_key() {  # first connected serial; needed because `reconnect` requires one
  timeout 15 hdc list targets 2>/dev/null \
    | awk 'NF>0 && $1 !~ /^\[/ {print $1; exit}'
}

# The only reliable liveness check. `list targets` is NOT a probe: it is
# answered by the local server, so it stays healthy while the device has
# stopped replying. Nor can the exit code be used -- `hdc shell` with no device
# prints "[Fail]ExecuteCommand need connect-key?" to STDOUT and exits 0 -- so
# the probe must match the actual round-trip payload.
hdc_probe() {
  local out
  out="$(hdc_t 15 shell "echo $HDC_PROBE_MARK" 2>/dev/null)" || return 1
  [ "${out//$'\r'/}" = "$HDC_PROBE_MARK" ]
}

# Wait for the session to become genuinely usable. Measured: after
# `reconnect` the device reappears in `list targets` well before `shell` works
# again (it answers "need connect-key" for a while), so the probe -- not
# `list targets` -- is what gets polled. Always makes at least one attempt:
# `kill -r` was measured healthy at 0s, and a budget of 0 must not turn that
# into a false failure.
hdc_wait_healthy() {
  local i=0
  while : ; do
    hdc_probe && return 0
    i=$((i + 1))
    [ "$i" -lt "$HDOS_HDC_WAIT" ] || return 1
    sleep 1
  done
}

# Escalating reset. `reconnect` goes first because it is the light one (session
# reset + USB re-enumerate, ~3s, other sessions untouched); restarting the
# server is faster (measured 0s) but disturbs everything else using hdc. Every
# step is probe-checked, since neither exit codes nor `list targets` can be
# trusted.
hdc_recover() {
  local key
  key="$(hdc_key || true)"
  if [ -n "$key" ]; then
    echo "hdc: resetting session (reconnect $key)" >&2
    timeout 30 hdc reconnect "$key" >/dev/null 2>&1 || true
    if hdc_wait_healthy; then
      echo "hdc: session healthy" >&2
      return 0
    fi
    echo "hdc: reconnect did not help -- restarting the hdc server" >&2
  else
    echo "hdc: no connected device key -- restarting the hdc server" >&2
  fi
  timeout 30 hdc kill -r >/dev/null 2>&1 || true
  if hdc_wait_healthy; then
    echo "hdc: session healthy after server restart" >&2
    return 0
  fi
  echo "hdc: device still not answering 'hdc shell' -- check the tablet" >&2
  return 1
}

# Run an hdc command with the guard: timing out (not any error) triggers one
# recovery attempt and one retry, so a wedged session self-heals instead of
# poisoning every later command.
hdc_g() {
  local t="$1"; shift
  local rc=0
  hdc_t "$t" "$@" || rc=$?
  [ "$rc" -eq 124 ] || return "$rc"
  echo "hdc: '$*' gave no reply within ${t}s (docs/toolchain/03-踩过的坑.md 「坑 1」)" >&2
  hdc_recover || return 124
  echo "hdc: retrying '$*'" >&2
  hdc_t "$t" "$@"
}

# devecocli's networked subcommands (auth/signature/update/emulator image/create)
# fail SILENTLY when http_proxy/https_proxy are set: `auth status` prints
# "Not logged in" and still exits 0. Strip the proxy vars by default.
# If you genuinely need a proxy to reach the network, export HDOS_KEEP_PROXY=1.
devecocli_() {
  if [ -n "${HDOS_KEEP_PROXY:-}" ]; then
    command devecocli "$@"
  else
    env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY devecocli "$@"
  fi
}

die() { echo "error: $*" >&2; exit 1; }

require_project() {
  [ -f "$ROOT/build-profile.json5" ] \
    || die "no build-profile.json5 in $ROOT - run this from a HarmonyOS project root"
}

detect_bundle() {
  if [ -n "${BUNDLE_NAME:-}" ]; then printf '%s\n' "$BUNDLE_NAME"; return; fi
  local hit
  hit="$(grep -Rho '"bundleName"[[:space:]]*:[[:space:]]*"[^"]*"' \
          "$ROOT/AppScope/app.json5" "$ROOT"/entry/src/main/module.json5 2>/dev/null \
        | head -n1 | sed 's/.*"\([^"]*\)"$/\1/')"
  printf '%s\n' "$hit"
}

find_hap() {
  find "$ROOT" -type f -name '*-signed.hap' -path '*/outputs/*' -printf '%T@ %p\n' 2>/dev/null \
    | sort -rn | head -n1 | cut -d' ' -f2-
}

find_app() {
  find "$ROOT" -type f -name '*.app' -path '*/outputs/*' -printf '%T@ %p\n' 2>/dev/null \
    | sort -rn | head -n1 | cut -d' ' -f2-
}

cmd_help() {
  cat <<'EOF'
HarmonyOS dev helper

  doctor            show toolchain versions, connected devices, detected paths
  env               print resolved environment paths

  devices           list connected devices (hdc list targets)
  connect <ip:port> connect a device over TCP (wireless debugging)
  udid              print the device UDID (needed for the debug signing profile)
  shell [cmd...]    run a command on the device
  recover           reset a wedged hdc session (reconnect, else restart server)

  build [debug|release]   build HAP (default: debug)
  app               build the release .app package (for AppGallery)
  clean             clean build outputs
  lint              run Code Linter
  check             run ArkTS static checks

  install [hap]     install a HAP (defaults to the newest signed one)
  run [args...]     build+install+launch (devecocli run when available)
  stop              force-stop the app

  keepawake [ms]    override auto-sleep so the tablet stops locking (default 24h)
  keepawake-restore restore the default auto-sleep timeout
  hotreload-stop    stop the hvigor daemon left behind by `run --hotreload`

  log [args...]     stream hilog (extra args are passed through)
  errors            stream error-level logs only
  log-clear         clear the device log buffer

  ui                dump the UI node tree (devecocli ui layout)
  shot [file]       take a screenshot (devecocli ui screenshot)
  info              show installed app info (bm dump -n <bundle>)
  fport <l> <r>     forward a port, e.g. fport tcp:8080 tcp:8080
EOF
}

cmd_env() {
  echo "ROOT=$ROOT"
  echo "CLT_HOME=${CLT_HOME:-}"
  echo "DEVECO_CLI_CLT_PATH=${DEVECO_CLI_CLT_PATH:-}"
  echo "DEVECO_SDK_HOME=${DEVECO_SDK_HOME:-}"
  echo "HDC_HOME=${HDC_HOME:-}"
  echo "JAVA_HOME=${JAVA_HOME:-}"
  echo "BUNDLE_NAME=$(detect_bundle)"
  echo "ABILITY_NAME=${ABILITY_NAME:-EntryAbility}"
  echo "HDOS_TARGET=${HDOS_TARGET:-<default>}"
  echo "HDOS_HDC_TIMEOUT=${HDOS_HDC_TIMEOUT:-60}"
  echo "HDOS_KEEP_PROXY=${HDOS_KEEP_PROXY:-<unset: proxy stripped for devecocli>}"
}

cmd_doctor() {
  local tool
  for tool in node java hdc hvigorw ohpm devecocli codelinter hstack; do
    if have "$tool"; then
      printf '%-12s %s\n' "$tool" "$(command -v "$tool")"
    else
      printf '%-12s %s\n' "$tool" "MISSING"
    fi
  done
  echo
  echo "project     $([ -f "$ROOT/build-profile.json5" ] && echo 'found' || echo 'not found (docs-only repo?)')"
  echo "bundleName  $(detect_bundle)"
  echo "last hap    $(find_hap || true)"
  echo "last app    $(find_app || true)"
  echo
  if have hdc; then
    echo "devices:"
    hdc list targets || true
    # `list targets` alone does not prove the device is usable: a wedged
    # session keeps answering it while every `shell` command hangs.
    printf 'shell probe %s\n' \
      "$(hdc_probe && echo ok || echo 'DEAD (run: dev.sh recover)')"
  fi
}

cmd_devices() { hdc list targets; }

cmd_connect() {
  [ $# -ge 1 ] || die "usage: dev.sh connect <ip:port>"
  hdc_g "$HDOS_HDC_TIMEOUT" tconn "$1"
}

cmd_udid() {
  hdc_g "$HDOS_HDC_TIMEOUT" shell bm get -u
}

cmd_shell() {
  # Interactive `hdc shell` (no args) stays unguarded: a timeout would kill
  # the user's own session out from under them.
  if [ $# -eq 0 ]; then hdc_ shell; return; fi
  hdc_g "$HDOS_HDC_TIMEOUT" shell "$@"
}

cmd_recover() { hdc_recover; }

cmd_build() {
  require_project
  local mode="${1:-debug}"
  case "$mode" in
    debug|release) ;;
    *) die "mode must be debug or release" ;;
  esac
  if have devecocli; then
    devecocli_ build --build-mode "$mode"
  else
    hvigorw assembleHap -p buildMode="$mode" --no-daemon
  fi
}

# The .app bundle (for AppGallery) is a hvigor task. devecocli has no equivalent
# subcommand -- `devecocli build` only ever produces HAPs -- so this always goes
# through hvigorw.
cmd_app() {
  require_project
  hvigorw assembleApp --no-daemon
}

cmd_clean() {
  require_project
  hvigorw clean --no-daemon
}

# NOTE: `devecocli check lint` prints a "Files checked: 0" summary that does not
# reflect what it actually scanned. When the result matters, cross-check with the
# raw `codelinter -c code-linter.json5`.
cmd_lint() {
  if have devecocli; then devecocli_ check lint; else codelinter; fi
}

cmd_check() {
  have devecocli || die "devecocli not installed (npm i -g @deveco/deveco-cli@stable)"
  devecocli_ check arkts
}

cmd_install() {
  local hap="${1:-}"
  if [ -z "$hap" ]; then
    hap="$(find_hap || true)"
    [ -n "$hap" ] || die "no signed HAP found - run 'dev.sh build' first"
  fi
  [ -f "$hap" ] || die "HAP not found: $hap"
  echo "installing $hap"
  hdc_g "$HDOS_HDC_INSTALL_TIMEOUT" install "$hap"
}

cmd_run() {
  require_project
  if have devecocli; then
    devecocli_ run "$@"
    return
  fi
  local bundle ability
  bundle="$(detect_bundle)"
  [ -n "$bundle" ] || die "cannot detect bundleName - set BUNDLE_NAME"
  ability="${ABILITY_NAME:-EntryAbility}"
  cmd_build debug
  cmd_install
  hdc_g "$HDOS_HDC_TIMEOUT" shell aa start -b "$bundle" -a "$ability"
}

cmd_stop() {
  local bundle
  bundle="$(detect_bundle)"
  [ -n "$bundle" ] || die "cannot detect bundleName - set BUNDLE_NAME"
  hdc_g "$HDOS_HDC_TIMEOUT" shell aa force-stop "$bundle"
}

# `devecocli run --hotreload` leaves an hvigor daemon watching in the background;
# every later build waits on it until it is stopped explicitly. Killing the
# process by name is not the supported way out.
cmd_hotreload_stop() {
  have devecocli || die "devecocli not installed"
  devecocli_ run --hotreload stop
}

# `aa start` fails with 10106102 while the device is LOCKED (screen-off alone is
# not enough to trigger it -- waking the screen does not help). Overriding the
# auto-sleep timeout is the reliable workaround: a screen that never turns off
# never locks. The one unlock at the start of a session still needs a human.
cmd_keepawake() {
  local ms="${1:-86400000}"
  case "$ms" in
    ''|*[!0-9]*) die "usage: dev.sh keepawake [milliseconds]  (default 86400000 = 24h)" ;;
  esac
  echo "overriding auto-sleep to ${ms}ms (restore later with: dev.sh keepawake-restore)"
  hdc_g "$HDOS_HDC_TIMEOUT" shell "power-shell timeout -o $ms"
}

# NOTE: this restores the DEFAULT, so it also discards any OverrideTimeout the
# machine had before we touched it. Read the old value first if that matters:
#   hdc shell "hidumper -s PowerManagerService -a '-s'"
cmd_keepawake_restore() {
  hdc_g "$HDOS_HDC_TIMEOUT" shell "power-shell timeout -r"
}

# Streaming commands (hilog follows the device indefinitely) are deliberately
# NOT guarded: a timeout would cut the stream, and Ctrl-C is the intended exit.
cmd_log() { hdc_ hilog "$@"; }

cmd_errors() {
  echo "streaming error-level logs, Ctrl-C to stop"
  hdc_ hilog -L E
}

cmd_log_clear() { hdc_ hilog -r; }

cmd_ui() {
  have devecocli || die "devecocli not installed"
  devecocli_ ui layout
}

cmd_shot() {
  have devecocli || die "devecocli not installed"
  mkdir -p "$ARTIFACTS"
  local out="${1:-$ARTIFACTS/shot-$(date +%Y%m%d-%H%M%S).png}"
  devecocli_ ui screenshot --path "$out"
  echo "saved: $out"
}

cmd_info() {
  local bundle
  bundle="$(detect_bundle)"
  [ -n "$bundle" ] || die "cannot detect bundleName - set BUNDLE_NAME"
  hdc_g "$HDOS_HDC_TIMEOUT" shell bm dump -n "$bundle"
}

cmd_fport() {
  [ $# -eq 2 ] || die "usage: dev.sh fport <local> <remote>  e.g. fport tcp:8080 tcp:8080"
  hdc_g "$HDOS_HDC_TIMEOUT" fport "$1" "$2"
}

cmd="${1:-help}"
[ $# -gt 0 ] && shift

case "$cmd" in
  help|-h|--help) cmd_help ;;
  doctor)   cmd_doctor ;;
  env)      cmd_env ;;
  devices)  cmd_devices ;;
  connect)  cmd_connect "$@" ;;
  udid)     cmd_udid ;;
  shell)    cmd_shell "$@" ;;
  recover)  cmd_recover ;;
  build)    cmd_build "$@" ;;
  app)      cmd_app ;;
  clean)    cmd_clean ;;
  lint)     cmd_lint ;;
  check)    cmd_check ;;
  install)  cmd_install "$@" ;;
  run)      cmd_run "$@" ;;
  stop)     cmd_stop ;;
  keepawake)         cmd_keepawake "$@" ;;
  keepawake-restore) cmd_keepawake_restore ;;
  hotreload-stop)    cmd_hotreload_stop ;;
  log)      cmd_log "$@" ;;
  errors)   cmd_errors ;;
  log-clear) cmd_log_clear ;;
  ui)       cmd_ui ;;
  shot)     cmd_shot "$@" ;;
  info)     cmd_info ;;
  fport)    cmd_fport "$@" ;;
  *) echo "unknown command: $cmd" >&2; echo; cmd_help >&2; exit 1 ;;
esac
