#!/usr/bin/env bash

storage_lvm_command() {
  local action="${1:-list}"; shift || true
  case "$action" in
    install) install_packages lvm2 ;;
    list) pvs; vgs; lvs -a -o +devices ;;
    pv-create)
      require_args 1 "$#" 'netadmin storage lvm pv-create <partition>'; require_root; assert_device_path "$1"; confirm_destructive "$1"; run pvcreate "$1"
      ;;
    vg-create)
      require_args 2 "$#" 'netadmin storage lvm vg-create <vg> <pv>'; require_root; assert_lvm_name "$1"; assert_device_path "$2"; run vgcreate "$1" "$2"
      ;;
    vg-extend)
      require_args 2 "$#" 'netadmin storage lvm vg-extend <vg> <pv>'; require_root; assert_lvm_name "$1"; assert_device_path "$2"; run vgextend "$1" "$2"
      ;;
    lv-create)
      require_args 3 "$#" 'netadmin storage lvm lv-create <vg> <lv> <size>'; require_root
      assert_lvm_name "$1"; assert_lvm_name "$2"; assert_size "$3"
      if [[ "$3" == *%* ]]; then run lvcreate -l "$3" -n "$2" "$1"; else run lvcreate -L "$3" -n "$2" "$1"; fi
      ;;
    lv-extend) storage_lv_extend "$@" ;;
    *) die "LVM action không hỗ trợ: $action" ;;
  esac
}

storage_lv_extend() {
  require_args 2 "$#" 'netadmin storage lvm lv-extend <lv-path> <size>'
  require_root
  local lv="$1" size="$2" fs mountpoint
  assert_device_path "$lv"; assert_size "$size"; confirm "Mở rộng $lv thêm/đến $size?" || die "Đã hủy."
  if [[ "$size" == *%* ]]; then run lvextend -l "$size" "$lv"; else run lvextend -L "$size" "$lv"; fi
  fs="$(blkid -s TYPE -o value "$lv")"; mountpoint="$(findmnt -rn -S "$lv" -o TARGET | head -n1)"
  case "$fs" in
    xfs) [[ -n "$mountpoint" ]] || die "XFS phải được mount để grow"; run xfs_growfs "$mountpoint" ;;
    ext2|ext3|ext4) run resize2fs "$lv" ;;
    *) log_warn "Không tự resize filesystem loại '${fs:-unknown}'." ;;
  esac
  log_ok "Đã mở rộng logical volume: $lv"
}
