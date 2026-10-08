#!/usr/bin/env bash

samba_client_command() {
  local action="${1:-}"; shift || true
  case "$action" in
    list)
      require_args 1 "$#" 'netadmin samba client list //<server>/<share> [username]'; require_command smbclient
      if [[ -n "${2:-}" ]]; then smbclient "$1" -U "$2" -c ls; else smbclient "$1" -N -c ls; fi
      ;;
    copy) samba_client_copy "$@" ;;
    *) die "Client action không hỗ trợ: ${action:-<trống>}" ;;
  esac
}

samba_client_copy() {
  require_args 3 "$#" 'netadmin samba client copy //<server>/<share> <remote-item> <destination> [username]'
  require_root; require_command mount.cifs
  local share="$1" item="$2" destination="$3" username="${4:-}" mount_dir credentials=''
  [[ "$share" =~ ^//[^/]+/[^/]+$ ]] || die "Share phải có dạng //server/share"
  [[ "$item" != /* && "$item" != *'..'* ]] || die "Remote item không an toàn: $item"
  assert_abs_path "$destination"; mount_dir="$(mktemp -d)"
  SAMBA_CLIENT_MOUNT="$mount_dir"; SAMBA_CLIENT_CREDENTIALS=''
  trap samba_client_cleanup EXIT
  if [[ -n "$username" ]]; then
    credentials="$(mktemp)"; SAMBA_CLIENT_CREDENTIALS="$credentials"; chmod 600 "$credentials"
    printf 'username=%s\n' "$username" > "$credentials"
    read -r -s -p "Mật khẩu SMB cho $username: " password; printf '\n' >&2
    printf 'password=%s\n' "$password" >> "$credentials"; unset password
    run mount.cifs "$share" "$mount_dir" -o "credentials=$credentials"
  else
    run mount.cifs "$share" "$mount_dir" -o guest
  fi
  [[ -e "$mount_dir/$item" ]] || { umount "$mount_dir" 2>/dev/null || true; die "Không tìm thấy trên share: $item"; }
  run mkdir -p "$destination"; run cp -a "$mount_dir/$item" "$destination/"
  run umount "$mount_dir"; rmdir "$mount_dir"; [[ -z "$credentials" ]] || rm -f "$credentials"
  SAMBA_CLIENT_MOUNT=''; SAMBA_CLIENT_CREDENTIALS=''; trap - EXIT
  log_ok "Đã sao chép $item vào $destination"
}

samba_client_cleanup() {
  if [[ -n "${SAMBA_CLIENT_MOUNT:-}" ]]; then
    mountpoint -q "$SAMBA_CLIENT_MOUNT" 2>/dev/null && umount "$SAMBA_CLIENT_MOUNT" 2>/dev/null || true
    rmdir "$SAMBA_CLIENT_MOUNT" 2>/dev/null || true
  fi
  [[ -z "${SAMBA_CLIENT_CREDENTIALS:-}" ]] || rm -f "$SAMBA_CLIENT_CREDENTIALS"
}
