#!/usr/bin/env bash

ftp_user_command() {
  local action="${1:-list}"; shift || true
  case "$action" in
    add) require_args 2 "$#" 'netadmin ftp user add <username> <home>'; ftp_user_add "$1" "$2" ;;
    list) require_command getent; getent passwd | awk -F: '$7 ~ /(nologin|false)$/ && $6 ~ /^\/(srv\/ftp|home)\// {print $1 "\t" $6}' ;;
    remove) require_args 1 "$#" 'netadmin ftp user remove <username>'; ftp_user_remove "$1" ;;
    lock) require_args 1 "$#" 'netadmin ftp user lock <username>'; ftp_user_lock "$1" ;;
    unlock) require_args 1 "$#" 'netadmin ftp user unlock <username>'; ftp_user_unlock "$1" ;;
    *) die "FTP user action không hỗ trợ: $action" ;;
  esac
}

ftp_user_lock() {
  require_root; assert_identifier "$1"; getent passwd "$1" >/dev/null || die "User không tồn tại: $1"
  run usermod -L "$1"; log_ok "Đã khóa FTP user: $1"
}

ftp_user_unlock() {
  require_root; assert_identifier "$1"; getent passwd "$1" >/dev/null || die "User không tồn tại: $1"
  run usermod -U "$1"; log_ok "Đã mở khóa FTP user: $1"
}

ftp_user_add() {
  local username="$1" home="$2" actual_home
  require_root; assert_identifier "$username"; assert_abs_path "$home"
  getent passwd "$username" >/dev/null && die "User đã tồn tại: $username"
  actual_home="$(system_path "$home")"
  [[ -z "${NETADMIN_ROOT:-}" ]] || die "Không hỗ trợ tạo user bên trong NETADMIN_ROOT."
  run useradd -m -d "$home" -s /sbin/nologin "$username"
  if [[ "${NETADMIN_DRY_RUN:-0}" != 1 ]]; then
    passwd "$username"
  else
    log_info "Sẽ yêu cầu đặt mật khẩu cho $username"
  fi
  run chmod 0750 "$actual_home"
  ftp_prepare_selinux_path "$actual_home"
  log_ok "Đã tạo local FTP user: $username"
}

ftp_user_remove() {
  require_root; assert_identifier "$1"
  [[ -z "${NETADMIN_ROOT:-}" ]] || die "Không hỗ trợ xóa user bên trong NETADMIN_ROOT."
  getent passwd "$1" >/dev/null || die "User không tồn tại: $1"
  run userdel "$1"
  log_ok "Đã xóa tài khoản $1. Home directory không bị xóa."
}
