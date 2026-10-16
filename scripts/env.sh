#!/usr/bin/env bash
# HarmonyOS toolchain environment for Linux (Command Line Tools based, no IDE).
#
# Usage:
#   source scripts/env.sh
#
# Override any path by exporting it before sourcing, e.g.
#   export CLT_HOME=/opt/harmonyos/command-line-tools

CLT_HOME="${CLT_HOME:-$HOME/harmonyos/command-line-tools}"
JDK_HOME="${JDK_HOME:-$HOME/harmonyos/jdk-21}"

# DevEco CLI refuses to run on Linux unless this is set explicitly.
export CLT_HOME
export DEVECO_CLI_CLT_PATH="${DEVECO_CLI_CLT_PATH:-$CLT_HOME}"
export DEVECO_SDK_HOME="${DEVECO_SDK_HOME:-$CLT_HOME/sdk}"
export HDC_HOME="${HDC_HOME:-$DEVECO_SDK_HOME/default/openharmony/toolchains}"

# Prepend a directory once. Re-sourcing must not grow PATH, and must not
# discard directories other tools added in the meantime.
_hdos_path_add() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
}

# Added in reverse, so the resulting precedence is CLT bin, hvigor, ohpm,
# emulator, then HDC_HOME (the CLT's own hdc).
_hdos_path_add "$HDC_HOME"
_hdos_path_add "$CLT_HOME/emulator"
_hdos_path_add "$CLT_HOME/ohpm/bin"
_hdos_path_add "$CLT_HOME/hvigor/bin"
_hdos_path_add "$CLT_HOME/bin"

# Prefer a bundled JDK, otherwise fall back to the system JDK 21.
if [ -x "$JDK_HOME/bin/java" ]; then
  export JAVA_HOME="${JAVA_HOME:-$JDK_HOME}"
elif [ -z "${JAVA_HOME:-}" ] && command -v java >/dev/null 2>&1; then
  export JAVA_HOME="$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")"
fi

if [ -n "${JAVA_HOME:-}" ]; then
  _hdos_path_add "$JAVA_HOME/bin"
fi

# Device / app defaults. Override per shell when needed.
export HDOS_TARGET="${HDOS_TARGET:-}"       # hdc -t <serial>, empty = default device
export BUNDLE_NAME="${BUNDLE_NAME:-}"       # auto-detected by scripts/dev.sh when empty
export ABILITY_NAME="${ABILITY_NAME:-EntryAbility}"

_hdos_warn() {
  [ -d "$1" ] || echo "[env] warning: $2 not found at $1" >&2
}

_hdos_warn "$CLT_HOME" "Command Line Tools"
[ -x "$JDK_HOME/bin/java" ] || command -v java >/dev/null 2>&1 || \
  echo "[env] warning: no JDK found (set JDK_HOME to a JDK 21 install)" >&2

# Report the hdc that PATH actually resolves to, not a hard-coded candidate.
_hdos_hdc="$(command -v hdc 2>/dev/null || true)"
if [ -n "$_hdos_hdc" ]; then
  _hdos_hdc_ver="$("$_hdos_hdc" -v 2>/dev/null || true)"
  echo "[env] hdc: $_hdos_hdc (${_hdos_hdc_ver:-version unknown})"
else
  echo "[env] warning: hdc not found in PATH" >&2
fi
unset _hdos_hdc _hdos_hdc_ver

if command -v node >/dev/null 2>&1; then
  _major="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
  [ "$_major" -ge 22 ] 2>/dev/null || echo "[env] warning: Node.js >= 22 recommended (found $(node -v))" >&2
  unset _major
else
  echo "[env] warning: node not found in PATH" >&2
fi

echo "[env] CLT_HOME=$CLT_HOME"
echo "[env] DEVECO_SDK_HOME=$DEVECO_SDK_HOME"
