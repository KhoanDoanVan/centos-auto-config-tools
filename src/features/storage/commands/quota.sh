#!/usr/bin/env bash

storage_quota_command() {
  local action="${1:-}"; shift || true
  case "$action" in
    enable) storage_quota_enable "$@" ;;
    set) storage_quota_set "$@" ;;
    report) require_args 1 "$#" 'netadmin storage quota report <mountpoint>'; require_command repquota; repquota -s "$1" ;;
    *) die "Quota action không hỗ trợ: ${action:-<trống>}" ;;
  esac
}

storage_quota_enable() {
  require_args 1 "$#" 'netadmin storage quota enable <mountpoint>'; require_root
  local mountpoint="$1" source type fstab temporary
  assert_abs_path "$mountpoint"; mountpoint -q "$mountpoint" || die "Chưa mount: $mountpoint"
  install_packages quota
  source="$(findmnt -rn -T "$mountpoint" -o SOURCE)"; type="$(findmnt -rn -T "$mountpoint" -o FSTYPE)"; fstab="$(fstab_path)"
  backup_file "$fstab" storage >/dev/null; temporary="$(mktemp)"
  awk -v mp="$mountpoint" -v opts="$([[ "$type" == xfs ]] && echo uquota,gquota || echo usrquota,grpquota)" '
    $0 !~ /^[[:space:]]*#/ && $2==mp && $4 !~ /(^|,)usrquota(,|$)/ && $4 !~ /(^|,)uquota(,|$)/ {$4=$4 "," opts}
    {print}
  ' "$fstab" > "$temporary"
  run install -m 0644 "$temporary" "$fstab"; rm -f "$temporary"
  run mount -o remount "$mountpoint"
  if [[ "$type" != xfs ]]; then run quotacheck -cugm "$mountpoint"; run quotaon -vug "$mountpoint"; fi
  log_ok "Đã bật user/group quota cho $mountpoint ($source, $type)"
}

storage_quota_set() {
  require_args 6 "$#" 'netadmin storage quota set <mountpoint> <user> <soft-blocks> <hard-blocks> <soft-inodes> <hard-inodes>'
  require_root
  local mountpoint="$1" user="$2"; shift 2
  assert_abs_path "$mountpoint"; id "$user" >/dev/null 2>&1 || die "User không tồn tại: $user"
  local value; for value in "$@"; do assert_uint "$value"; done
  run setquota -u "$user" "$1" "$2" "$3" "$4" "$mountpoint"
  log_ok "Đã đặt quota cho $user tại $mountpoint"
}
