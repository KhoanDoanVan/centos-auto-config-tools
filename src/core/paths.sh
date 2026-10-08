#!/usr/bin/env bash

# NETADMIN_ROOT cho phép dựng cấu hình vào một rootfs khác (mặc định là hệ thống thật).
system_path() {
  local path="$1" root="${NETADMIN_ROOT:-}"
  if [[ -n "$root" ]]; then
    printf '%s%s\n' "${root%/}" "$path"
  else
    printf '%s\n' "$path"
  fi
}

ensure_parent_dir() {
  run mkdir -p "$(dirname "$1")"
}
