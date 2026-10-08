#!/usr/bin/env bash

on_unexpected_error() {
  local status="$1" line="$2" command="$3"
  [[ "$status" -eq 0 ]] && return
  log_error "Lệnh thất bại tại dòng $line (exit=$status): $command"
}

require_root() {
  [[ "${EUID:-$(id -u)}" -eq 0 ]] || die "Tác vụ này cần quyền root. Hãy chạy bằng sudo."
}

require_args() {
  local minimum="$1" actual="$2" usage="$3"
  (( actual >= minimum )) || die "Cách dùng: $usage"
}
