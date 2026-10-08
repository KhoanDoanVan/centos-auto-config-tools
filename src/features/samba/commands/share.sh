#!/usr/bin/env bash

samba_share_command() {
  local action="${1:-list}"; shift || true
  case "$action" in
    add-public) samba_share_add public "$@" ;;
    add-group) samba_share_add group "$@" ;;
    list) grep '^# NETADMIN:SHARE:.*:BEGIN$' "$(samba_config_path)" 2>/dev/null | cut -d: -f3 || true ;;
    remove) require_args 1 "$#" 'netadmin samba share remove <name>'; samba_share_remove "$1" ;;
    *) die "Share action không hỗ trợ: $action" ;;
  esac
}

samba_share_add() {
  local kind="$1"; shift
  local required=2 usage group='' mode config writable backup
  [[ "$kind" == group ]] && required=3
  usage="netadmin samba share add-$kind <name> <path>$([[ "$kind" == group ]] && echo ' <group>') [read-only|read-write]"
  require_args "$required" "$#" "$usage"; require_root
  local name="$1" path="$2"; shift 2
  assert_identifier "$name"; assert_abs_path "$path"
  if [[ "$kind" == group ]]; then group="$1"; shift; getent group "$group" >/dev/null || die "Group không tồn tại: $group"; fi
  mode="${1:-read-write}"; [[ "$mode" == read-only || "$mode" == read-write ]] || die "Mode chỉ nhận read-only/read-write"
  writable=$([[ "$mode" == read-write ]] && echo yes || echo no)
  samba_ensure_config; config="$(samba_config_path)"
  grep -Fqx "# NETADMIN:SHARE:$name:BEGIN" "$config" && die "Share đã tồn tại: $name"
  run mkdir -p "$path"
  if [[ "$kind" == public ]]; then
    run chown nobody:nobody "$path"; run chmod "$([[ "$mode" == read-write ]] && echo 0777 || echo 0755)" "$path"
  else
    run chown root:"$group" "$path"; run chmod "$([[ "$mode" == read-write ]] && echo 2770 || echo 2750)" "$path"
  fi
  samba_prepare_selinux_path "$path"; backup="$(backup_file "$config" samba)"
  if [[ "${NETADMIN_DRY_RUN:-0}" != 1 ]]; then
    {
      printf '\n# NETADMIN:SHARE:%s:BEGIN\n[%s]\n  path = %s\n' "$name" "$name" "$path"
      if [[ "$kind" == public ]]; then printf '  guest ok = yes\n  guest only = yes\n'; else printf '  guest ok = no\n  valid users = @%s\n  force group = %s\n' "$group" "$group"; fi
      printf '  read only = %s\n  browseable = yes\n  create mask = 0660\n  directory mask = 0770\n# NETADMIN:SHARE:%s:END\n' "$([[ "$writable" == yes ]] && echo no || echo yes)" "$name"
    } >> "$config"
  fi
  samba_check || { restore_backup_now "$config" "$backup"; die "Cấu hình lỗi; đã rollback."; }
  log_ok "Đã tạo Samba share: $name -> $path"
}

samba_share_remove() {
  require_root; assert_identifier "$1"
  local config backup; config="$(samba_config_path)"; backup="$(backup_file "$config" samba)"
  samba_remove_share_block "$1" || die "Không tìm thấy share: $1"
  samba_check || { restore_backup_now "$config" "$backup"; die "Cấu hình lỗi; đã rollback."; }
  log_ok "Đã gỡ share $1 (không xóa dữ liệu)."
}
