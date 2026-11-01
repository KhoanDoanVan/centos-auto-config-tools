#!/usr/bin/env bash

mail_user_command() {
  local action="${1:-list}"; shift || true
  case "$action" in
    add) require_args 1 "$#" 'netadmin mail user add <username>'; mail_user_add "$1" ;;
    list) mail_user_list ;;
    remove) require_args 1 "$#" 'netadmin mail user remove <username>'; mail_user_remove "$1" ;;
    *) die "Mail user action không hỗ trợ: $action" ;;
  esac
}

mail_user_add() {
  local username="$1" home group
  require_root; assert_identifier "$username"
  [[ -z "${NETADMIN_ROOT:-}" ]] || die "Không hỗ trợ tạo user bên trong NETADMIN_ROOT."
  getent passwd "$username" >/dev/null && die "User đã tồn tại: $username"
  run useradd -m "$username"
  if [[ "${NETADMIN_DRY_RUN:-0}" != 1 ]]; then passwd "$username"; else log_info "Sẽ yêu cầu đặt mật khẩu cho $username"; fi
  home="$(getent passwd "$username" 2>/dev/null | cut -d: -f6)"
  group="$(id -gn "$username" 2>/dev/null || true)"
  if [[ -n "$home" && -n "$group" ]]; then
    run install -d -m 0700 -o "$username" -g "$group" \
      "$home/Maildir" "$home/Maildir/cur" "$home/Maildir/new" "$home/Maildir/tmp"
  fi
  log_ok "Đã tạo mail user: $username"
}

mail_user_list() {
  local minimum_uid="${MAIL_MIN_UID:-1000}"
  require_command getent
  getent passwd | awk -F: -v min="$minimum_uid" '$3>=min && $3<65534 {printf "%-24s %s\n", $1, $6}'
}

mail_user_remove() {
  require_root; assert_identifier "$1"
  [[ -z "${NETADMIN_ROOT:-}" ]] || die "Không hỗ trợ xóa user bên trong NETADMIN_ROOT."
  getent passwd "$1" >/dev/null || die "User không tồn tại: $1"
  run userdel "$1"
  log_ok "Đã xóa tài khoản $1. Home và Maildir không bị xóa."
}
