#!/usr/bin/env bash

backup_file() {
  local source="$1" label="${2:-config}" backup_dir stamp destination
  [[ -e "$source" ]] || return 0
  backup_dir="$(system_path "$NETADMIN_BACKUP_DIR/$label")"
  stamp="$(date +%Y%m%d-%H%M%S)"
  run mkdir -p "$backup_dir"
  destination="$backup_dir/$(basename "$source").$stamp.bak"
  run cp -a "$source" "$destination"
  log_info "Backup: $destination"
  printf '%s\n' "$destination"
}

latest_backup() {
  local label="$1" filename="$2" directory
  directory="$(system_path "$NETADMIN_BACKUP_DIR/$label")"
  [[ -d "$directory" ]] || return 1
  find "$directory" -maxdepth 1 -type f -name "$filename.*.bak" -print 2>/dev/null | sort -r | head -n1
}

restore_latest_backup() {
  local target="$1" label="$2" backup
  backup="$(latest_backup "$label" "$(basename "$target")")" || die "Không tìm thấy backup cho $target"
  confirm "Khôi phục $target từ $backup?" || die "Đã hủy."
  run cp -a "$backup" "$target"
  log_ok "Đã rollback $target"
}

restore_backup_now() {
  local target="$1" backup="$2"
  [[ -n "$backup" && -e "$backup" ]] || die "Không thể rollback: backup không tồn tại."
  run cp -a "$backup" "$target"
  log_warn "Đã tự động rollback $target từ $backup"
}
