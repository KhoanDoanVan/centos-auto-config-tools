#!/usr/bin/env bash

samba_user_command() {
  local action="${1:-list}"; shift || true
  case "$action" in
    add)
      require_args 2 "$#" 'netadmin samba user add <username> <group>'; require_root
      assert_identifier "$1"; assert_identifier "$2"
      getent group "$2" >/dev/null || run groupadd "$2"
      id "$1" >/dev/null 2>&1 || run useradd -M -s /sbin/nologin -G "$2" "$1"
      run usermod -aG "$2" "$1"; run smbpasswd -a "$1"
      log_ok "Đã thêm Samba user: $1"
      ;;
    remove)
      require_args 1 "$#" 'netadmin samba user remove <username>'; require_root; assert_identifier "$1"
      run smbpasswd -x "$1"; log_warn "Chỉ xóa tài khoản Samba, giữ nguyên Linux user."
      ;;
    list) require_command pdbedit; pdbedit -L -v ;;
    *) die "User action không hỗ trợ: $action" ;;
  esac
}

samba_permissions_command() {
  local action="${1:-}"; shift || true
  [[ "$action" == grant ]] || die 'Cách dùng: netadmin samba permissions grant <share> <user|@group> <read|write>'
  require_args 3 "$#" 'netadmin samba permissions grant <share> <user|@group> <read|write>'; require_root
  local share="$1" principal="$2" access="$3" config temporary backup
  assert_identifier "$share"; [[ "$principal" =~ ^@?[A-Za-z0-9_.-]+$ ]] || die "Principal không hợp lệ"
  [[ "$access" == read || "$access" == write ]] || die "Access chỉ nhận read/write"
  config="$(samba_config_path)"; backup="$(backup_file "$config" samba)"; temporary="$(mktemp)"
  awk -v begin="# NETADMIN:SHARE:$share:BEGIN" -v p="$principal" -v a="$access" '
    $0==begin {inside=1; found=1}
    inside && /^[[:space:]]*(read|write) list[[:space:]]*=/ {next}
    inside && /^# NETADMIN:SHARE:.*:END$/ {print "  " a " list = " p; inside=0}
    {print}
    END {if(!found) exit 4}
  ' "$config" > "$temporary" || { rm -f "$temporary"; die "Không tìm thấy share: $share"; }
  run install -m 0644 "$temporary" "$config"; rm -f "$temporary"
  samba_check || { restore_backup_now "$config" "$backup"; die "Cấu hình lỗi; đã rollback."; }
  log_ok "Đã cấp quyền $access cho $principal trên $share"
}
