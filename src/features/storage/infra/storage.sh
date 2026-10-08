#!/usr/bin/env bash

assert_device_path() {
  [[ "$1" =~ ^/dev/[A-Za-z0-9._+-]+(/[A-Za-z0-9._+-]+)?$ ]] || die "Device path không hợp lệ: $1"
  if [[ "${NETADMIN_DRY_RUN:-0}" != 1 ]]; then [[ -b "$1" ]] || die "Không phải block device: $1"; fi
}

assert_lvm_name() { [[ "$1" =~ ^[A-Za-z0-9_+.-]+$ ]] || die "Tên LVM không hợp lệ: $1"; }
assert_size() { [[ "$1" =~ ^\+?[0-9]+([KMGTP]i?[Bb]?|%(FREE|VG|PVS|ORIGIN)?)?$ ]] || die "Kích thước không hợp lệ: $1"; }

storage_refresh_devices() {
  command_exists partprobe && run partprobe "$1"
  command_exists udevadm && run udevadm settle
}

fstab_path() { system_path /etc/fstab; }

fstab_add() {
  local source="$1" mountpoint="$2" type="$3" options="$4" fstab
  fstab="$(fstab_path)"; [[ -e "$fstab" ]] || write_stdin_file "$fstab" <<< '# /etc/fstab managed in part by NetAdmin Toolkit'
  grep -Eq "^[^#]+[[:space:]]+$mountpoint[[:space:]]" "$fstab" && die "Mountpoint đã có trong fstab: $mountpoint"
  backup_file "$fstab" storage >/dev/null
  if [[ "${NETADMIN_DRY_RUN:-0}" != 1 ]]; then printf '%s %s %s %s 0 0\n' "$source" "$mountpoint" "$type" "$options" >> "$fstab"; fi
}
