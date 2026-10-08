#!/usr/bin/env bash

if [[ -t 2 && "${NO_COLOR:-0}" != 1 ]]; then
  readonly C_RED=$'\033[31m' C_GREEN=$'\033[32m' C_YELLOW=$'\033[33m' C_BLUE=$'\033[34m' C_RESET=$'\033[0m'
else
  readonly C_RED='' C_GREEN='' C_YELLOW='' C_BLUE='' C_RESET=''
fi

log_info() { printf '%s[INFO]%s %s\n' "$C_BLUE" "$C_RESET" "$*" >&2; }
log_ok() { printf '%s[OK]%s %s\n' "$C_GREEN" "$C_RESET" "$*" >&2; }
log_warn() { printf '%s[WARN]%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
log_error() { printf '%s[ERROR]%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; }
die() { log_error "$*"; exit 1; }
