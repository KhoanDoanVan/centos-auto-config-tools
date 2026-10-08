#!/usr/bin/env bash

source "$APP_ROOT/src/features/storage/infra/storage.sh"
source "$APP_ROOT/src/features/storage/commands/disk.sh"
source "$APP_ROOT/src/features/storage/commands/filesystem.sh"
source "$APP_ROOT/src/features/storage/commands/lvm.sh"
source "$APP_ROOT/src/features/storage/commands/quota.sh"

storage_help() {
  cat <<'EOF'
Cách dùng: netadmin storage <command> [arguments]

  disk list | disk free <device>
  partition create <device> <start> <end> [gpt|msdos]
  filesystem format <partition> <xfs|ext4|ext3> [label]
  filesystem mount <partition> <mountpoint> [defaults]
  filesystem list
  lvm install | lvm list
  lvm pv-create <partition>
  lvm vg-create <vg> <pv> | lvm vg-extend <vg> <pv>
  lvm lv-create <vg> <lv> <size> | lvm lv-extend <lv-path> <size>
  quota enable <mountpoint> | quota set <mountpoint> <user> <soft-blocks> <hard-blocks> <soft-inodes> <hard-inodes>
  quota report <mountpoint>

Các lệnh partition/format/LVM ghi trực tiếp lên disk và luôn yêu cầu nhập lại target.
EOF
}

storage_command() {
  local command="${1:-help}"; shift || true
  case "$command" in
    disk) storage_disk_command "$@" ;;
    partition) storage_partition_command "$@" ;;
    filesystem) storage_filesystem_command "$@" ;;
    lvm) storage_lvm_command "$@" ;;
    quota) storage_quota_command "$@" ;;
    help|-h|--help) storage_help ;;
    *) storage_help; die "Storage command không hỗ trợ: $command" ;;
  esac
}
