#!/usr/bin/env bash

storage_filesystem_command() {
  local action="${1:-list}"; shift || true
  case "$action" in
    list) lsblk -f; printf '\n'; findmnt --real ;;
    format) storage_filesystem_format "$@" ;;
    mount) storage_filesystem_mount "$@" ;;
    *) die "Filesystem action không hỗ trợ: $action" ;;
  esac
}

storage_filesystem_format() {
  require_args 2 "$#" 'netadmin storage filesystem format <partition> <xfs|ext4|ext3> [label]'
  require_root
  local device="$1" type="$2" label="${3:-}"
  assert_device_path "$device"; [[ "$type" =~ ^(xfs|ext4|ext3)$ ]] || die "Filesystem không hỗ trợ: $type"
  [[ -z "$label" ]] || assert_identifier "$label"
  findmnt -rn -S "$device" >/dev/null 2>&1 && die "Device đang được mount: $device"
  confirm_destructive "$device"
  case "$type" in
    xfs) require_command mkfs.xfs; if [[ -n "$label" ]]; then run mkfs.xfs -f -L "$label" "$device"; else run mkfs.xfs -f "$device"; fi ;;
    ext4) require_command mkfs.ext4; if [[ -n "$label" ]]; then run mkfs.ext4 -F -L "$label" "$device"; else run mkfs.ext4 -F "$device"; fi ;;
    ext3) require_command mkfs.ext3; if [[ -n "$label" ]]; then run mkfs.ext3 -F -L "$label" "$device"; else run mkfs.ext3 -F "$device"; fi ;;
  esac
  log_ok "Đã format $device thành $type"
}

storage_filesystem_mount() {
  require_args 2 "$#" 'netadmin storage filesystem mount <partition> <mountpoint> [options]'
  require_root
  local device="$1" mountpoint="$2" options="${3:-defaults}" uuid type
  assert_device_path "$device"; assert_abs_path "$mountpoint"; [[ "$options" != *[[:space:]]* ]] || die "Mount options không hợp lệ"
  require_command blkid
  uuid="$(blkid -s UUID -o value "$device")"; type="$(blkid -s TYPE -o value "$device")"
  [[ -n "$uuid" && -n "$type" ]] || die "Không xác định được UUID/filesystem của $device"
  run mkdir -p "$mountpoint"
  fstab_add "UUID=$uuid" "$mountpoint" "$type" "$options"
  run mount "$mountpoint"
  log_ok "Đã mount $device tại $mountpoint và ghi fstab"
}
