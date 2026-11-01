#!/usr/bin/env bash

ftp_share_command() {
  local action="${1:-list}"; shift || true
  case "$action" in
    add-anonymous) require_args 1 "$#" 'netadmin ftp share add-anonymous <name> [read-only|read-write]'; ftp_share_add_anonymous "$@" ;;
    list) ftp_share_list ;;
    remove) require_args 1 "$#" 'netadmin ftp share remove <name>'; ftp_share_remove "$1" ;;
    backup) require_args 1 "$#" 'netadmin ftp share backup <name>'; ftp_share_backup "$1" ;;
    restore) require_args 1 "$#" 'netadmin ftp share restore <name> [backup-dir]'; ftp_share_restore "$@" ;;
    *) die "FTP share action không hỗ trợ: $action" ;;
  esac
}

ftp_share_add_anonymous() {
  local name="$1" mode="${2:-read-only}" root logical_path path config backup
  require_root; assert_identifier "$name"
  [[ "$mode" == read-only || "$mode" == read-write ]] || die "Mode chỉ nhận read-only/read-write"
  root="${FTP_ROOT:-/var/ftp}"; logical_path="${root%/}/$name"; path="$(system_path "$logical_path")"
  config="$(ftp_config_path)"; backup="$(backup_file "$config" ftp)"
  run mkdir -p "$path"
  run chown root:root "$path"
  run chmod "$([[ "$mode" == read-write ]] && echo 0777 || echo 0755)" "$path"
  ftp_prepare_selinux_path "$path"
  ftp_set_option anonymous_enable YES
  if [[ "$mode" == read-write ]]; then
    ftp_set_option anon_upload_enable YES
    ftp_set_option anon_mkdir_write_enable YES
    selinux_enable_boolean ftpd_anon_write
  fi
  ftp_registry_add "$name" "$logical_path" "$mode"
  ftp_check || { restore_backup_now "$config" "$backup"; die "Cấu hình lỗi; đã rollback."; }
  log_ok "Đã tạo anonymous FTP share: $name -> $logical_path"
}

ftp_share_list() {
  local registry; registry="$(ftp_share_registry)"
  [[ -r "$registry" ]] && awk '!/^#/ && NF {printf "%-24s %-40s %s\n", $1, $2, $3}' "$registry" || true
}

ftp_share_remove() {
  local name="$1" entry logical_path mode source destination
  require_root; assert_identifier "$name"
  entry="$(ftp_registry_lookup "$name")" || die "Không tìm thấy FTP share: $name"
  IFS=$'\t' read -r logical_path mode <<< "$entry"
  source="$(system_path "$logical_path")"
  destination="$(ftp_share_snapshot_path "$name")"
  ftp_share_write_snapshot "$name" "$logical_path" "$mode" "$source" "$destination" move
  if ! ftp_registry_remove "$name"; then
    if [[ -d "$destination/data" && ! -e "$source" ]]; then run mv -- "$destination/data" "$source"; fi
    die "Không thể cập nhật FTP registry; đã trả dữ liệu về $logical_path"
  fi
  log_ok "Đã gỡ share $name; dữ liệu được cách ly tại $destination"
}

ftp_share_snapshot_path() {
  local name="$1" stamp
  stamp="$(date +%Y%m%d-%H%M%S)"
  printf '%s/%s-%s\n' "$(ftp_share_backup_dir)" "$name" "$stamp"
}

ftp_share_write_snapshot() {
  local name="$1" logical_path="$2" mode="$3" source="$4" destination="$5" operation="$6"
  run mkdir -p "$destination"
  if [[ "${NETADMIN_DRY_RUN:-0}" == 1 ]]; then
    log_info "Sẽ ghi metadata cho $name vào $destination/metadata.tsv"
  else
    printf '%s\t%s\t%s\n' "$name" "$logical_path" "$mode" > "$destination/metadata.tsv"
  fi
  if [[ -e "$source" ]]; then
    if [[ "$operation" == move ]]; then run mv -- "$source" "$destination/data"; else run cp -a -- "$source" "$destination/data"; fi
  else
    log_warn "Thư mục share không tồn tại: $logical_path; chỉ lưu metadata."
  fi
}

ftp_share_backup() {
  local name="$1" entry logical_path mode source destination
  require_root; assert_identifier "$name"
  entry="$(ftp_registry_lookup "$name")" || die "Không tìm thấy FTP share: $name"
  IFS=$'\t' read -r logical_path mode <<< "$entry"
  source="$(system_path "$logical_path")"; destination="$(ftp_share_snapshot_path "$name")"
  ftp_share_write_snapshot "$name" "$logical_path" "$mode" "$source" "$destination" copy
  log_ok "Đã backup FTP share $name tại $destination"
}

ftp_share_restore() {
  local name="$1" snapshot="${2:-}" base base_real metadata saved_name logical_path mode target ftp_root
  require_root; assert_identifier "$name"; base="$(ftp_share_backup_dir)"
  if [[ -z "$snapshot" ]]; then
    snapshot="$(find "$base" -mindepth 1 -maxdepth 1 -type d -name "${name}-*" -print 2>/dev/null | sort -r | head -n1)"
  else
    assert_abs_path "$snapshot"
    [[ "$snapshot" == "$base"/* ]] || die "Backup phải nằm trong $base"
  fi
  [[ -n "$snapshot" && -d "$snapshot" ]] || die "Không tìm thấy backup cho FTP share $name"
  require_command realpath
  base_real="$(realpath -e "$base")"; snapshot="$(realpath -e "$snapshot")"
  [[ "$snapshot" == "$base_real"/* ]] || die "Backup phải nằm trực tiếp trong $base"
  metadata="$snapshot/metadata.tsv"; [[ -r "$metadata" ]] || die "Thiếu metadata: $metadata"
  IFS=$'\t' read -r saved_name logical_path mode < "$metadata"
  [[ "$saved_name" == "$name" ]] || die "Backup thuộc share khác: $saved_name"
  assert_abs_path "$logical_path"; ftp_root="${FTP_ROOT:-/var/ftp}"
  [[ "$logical_path" == "${ftp_root%/}/"* ]] || die "Đường dẫn restore phải nằm trong ${ftp_root%/}/"
  [[ "$mode" == read-only || "$mode" == read-write ]] || die "Metadata mode không hợp lệ"
  ftp_registry_lookup "$name" >/dev/null 2>&1 && die "Share đã tồn tại trong registry: $name"
  target="$(system_path "$logical_path")"; [[ ! -e "$target" ]] || die "Đường dẫn restore đã tồn tại: $logical_path"
  if [[ -d "$snapshot/data" ]]; then
    find "$snapshot/data" -type l -print -quit | grep -q . && die 'Backup chứa symlink; từ chối restore.'
    run cp -a -- "$snapshot/data" "$target"
  else
    run mkdir -p "$target"
  fi
  ftp_prepare_selinux_path "$target"
  ftp_registry_add "$name" "$logical_path" "$mode"
  log_ok "Đã restore FTP share $name -> $logical_path"
}
