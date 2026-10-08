#!/usr/bin/env bash

storage_disk_command() {
  local action="${1:-list}"; shift || true
  case "$action" in
    list) require_command lsblk; lsblk -e 7 -o NAME,PATH,SIZE,TYPE,FSTYPE,MOUNTPOINTS,MODEL ;;
    free) require_args 1 "$#" 'netadmin storage disk free <device>'; assert_device_path "$1"; require_command parted; parted -s "$1" unit GiB print free ;;
    *) die "Disk action không hỗ trợ: $action" ;;
  esac
}

storage_partition_command() {
  local action="${1:-}"; shift || true
  [[ "$action" == create ]] || die 'Cách dùng: netadmin storage partition create <device> <start> <end> [gpt|msdos]'
  require_args 3 "$#" 'netadmin storage partition create <device> <start> <end> [gpt|msdos]'
  require_root; require_command parted
  local device="$1" start="$2" end="$3" table="${4:-}" 
  assert_device_path "$device"
  [[ "$start" =~ ^[0-9.]+(MiB|GiB|MB|GB|%)$ ]] || die "Start không hợp lệ: $start"
  [[ "$end" =~ ^[0-9.]+(MiB|GiB|MB|GB|%)$ ]] || die "End không hợp lệ: $end"
  [[ -z "$table" || "$table" == gpt || "$table" == msdos ]] || die "Partition table chỉ nhận gpt hoặc msdos"
  confirm_destructive "$device"
  [[ -z "$table" ]] || run parted -s "$device" mklabel "$table"
  run parted -s -a optimal "$device" mkpart primary "$start" "$end"
  storage_refresh_devices "$device"
  log_ok "Đã tạo partition trên $device"
}
