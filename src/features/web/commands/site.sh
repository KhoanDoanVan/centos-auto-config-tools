#!/usr/bin/env bash

web_site_command() {
  local action="${1:-list}"; shift || true
  case "$action" in
    add) require_args 2 "$#" 'netadmin web site add <domain> <document-root>'; web_site_add "$1" "$2" ;;
    list) web_site_list ;;
    show) require_args 1 "$#" 'netadmin web site show <domain>'; web_site_show "$1" ;;
    remove) require_args 1 "$#" 'netadmin web site remove <domain>'; web_site_remove "$1" ;;
    backup) require_args 1 "$#" 'netadmin web site backup <domain>'; web_site_backup "$1" ;;
    restore) require_args 1 "$#" 'netadmin web site restore <domain> [archive]'; web_site_restore "$@" ;;
    *) die "Web site action không hỗ trợ: $action" ;;
  esac
}

web_site_add() {
  local domain="$1" document_root="$2" config root_path temporary backup=''
  require_root; assert_domain "$domain"; assert_abs_path "$document_root"
  config="$(web_site_config "$domain")"; root_path="$(system_path "$document_root")"
  [[ ! -e "$config" ]] || die "Website đã tồn tại: $domain"
  run mkdir -p "$root_path" "$(web_config_dir)"
  if [[ ! -e "$root_path/index.html" ]]; then
    write_stdin_file "$root_path/index.html" 0644 <<EOF
<!doctype html>
<html lang="vi"><head><meta charset="utf-8"><title>$domain</title></head>
<body><h1>$domain</h1><p>Website được quản lý bởi NetAdmin Toolkit.</p></body></html>
EOF
  fi
  temporary="$(mktemp)"
  cat > "$temporary" <<EOF
# NETADMIN:WEB:$domain
<VirtualHost *:80>
    ServerName $domain
    DocumentRoot "$document_root"
    ErrorLog logs/${domain}-error.log
    CustomLog logs/${domain}-access.log combined
    <Directory "$document_root">
        AllowOverride None
        Require all granted
    </Directory>
</VirtualHost>
EOF
  run install -m 0644 "$temporary" "$config"; rm -f "$temporary"
  web_prepare_selinux_path "$root_path"
  web_check || { [[ -n "$backup" ]] && restore_backup_now "$config" "$backup"; run rm -f -- "$config"; die "Cấu hình Apache lỗi; đã gỡ VirtualHost mới."; }
  log_ok "Đã tạo website $domain -> $document_root"
  log_info "Nếu dùng DNS, hãy thêm A record bằng module dns."
}

web_site_list() {
  local directory; directory="$(web_config_dir)"
  [[ -d "$directory" ]] || return 0
  grep -h '^# NETADMIN:WEB:' "$directory"/netadmin-*.conf 2>/dev/null | cut -d: -f3 || true
}

web_site_show() {
  assert_domain "$1"
  local config; config="$(web_site_config "$1")"
  [[ -r "$config" ]] || die "Không tìm thấy website: $1"
  cat "$config"
}

web_site_remove() {
  require_root; assert_domain "$1"
  local config backup; config="$(web_site_config "$1")"
  [[ -e "$config" ]] || die "Không tìm thấy website: $1"
  backup="$(backup_file "$config" web)"
  run rm -f -- "$config"
  web_check || { restore_backup_now "$config" "$backup"; die "Cấu hình lỗi; đã rollback."; }
  log_ok "Đã gỡ VirtualHost $1. Dữ liệu website không bị xóa."
}

web_site_document_root() {
  local config="$1" value
  value="$(sed -n 's/^[[:space:]]*DocumentRoot[[:space:]]*"\(.*\)"[[:space:]]*$/\1/p' "$config" | head -n1)"
  [[ -n "$value" ]] || die "Không đọc được DocumentRoot từ $config"
  assert_abs_path "$value"
  printf '%s\n' "$value"
}

web_site_backup_dir() { system_path "${WEB_SITE_BACKUP_DIR:-$NETADMIN_BACKUP_DIR/web-sites}"; }

web_site_backup() {
  require_root; assert_domain "$1"
  [[ -z "${NETADMIN_ROOT:-}" ]] || die "Không hỗ trợ website archive bên trong NETADMIN_ROOT."
  local domain="$1" config document_root directory archive stage stamp
  config="$(web_site_config "$domain")"; [[ -r "$config" ]] || die "Không tìm thấy website: $domain"
  document_root="$(web_site_document_root "$config")"; [[ -d "$document_root" ]] || die "DocumentRoot không tồn tại: $document_root"
  directory="$(web_site_backup_dir)"; stamp="$(date +%Y%m%d-%H%M%S)"
  archive="$directory/web-site-$(web_domain_key "$domain")-$stamp.tar.gz"
  if [[ "${NETADMIN_DRY_RUN:-0}" == 1 ]]; then log_info "Sẽ tạo website backup: $archive"; return; fi
  stage="$(mktemp -d)"; mkdir -p "$directory" "$stage/document-root"
  cp -a "$config" "$stage/config.conf"
  cp -a "$document_root/." "$stage/document-root/"
  printf 'domain=%s\ndocument_root=%s\n' "$domain" "$document_root" > "$stage/metadata"
  tar -C "$stage" -czf "$archive" metadata config.conf document-root
  rm -rf -- "$stage"
  log_ok "Đã backup website: $archive"
}

web_site_restore() {
  require_root; assert_domain "$1"
  [[ -z "${NETADMIN_ROOT:-}" ]] || die "Không hỗ trợ website archive bên trong NETADMIN_ROOT."
  local domain="$1" archive="${2:-}" directory key stage metadata_domain document_root config backup=''
  directory="$(web_site_backup_dir)"; key="$(web_domain_key "$domain")"
  if [[ -z "$archive" ]]; then
    archive="$(find "$directory" -maxdepth 1 -type f -name "web-site-${key}-*.tar.gz" -print 2>/dev/null | sort -r | head -n1)"
  fi
  [[ -n "$archive" && -r "$archive" ]] || die "Không tìm thấy backup cho website $domain"
  if [[ "${NETADMIN_DRY_RUN:-0}" == 1 ]]; then log_info "Sẽ restore website từ: $archive"; return; fi
  if ! tar -tzf "$archive" | awk '
    $0=="metadata" || $0=="config.conf" || $0=="document-root" || $0=="document-root/" || index($0,"document-root/")==1 {next}
    {exit 1}
  '; then die "Archive chứa đường dẫn không được phép."; fi
  if ! tar -tvzf "$archive" | awk 'substr($1,1,1)!="-" && substr($1,1,1)!="d" {exit 1}'; then
    die "Archive chứa symlink hoặc kiểu file không được phép."
  fi
  stage="$(mktemp -d)"
  tar -C "$stage" -xzf "$archive"
  [[ -r "$stage/metadata" && -r "$stage/config.conf" && -d "$stage/document-root" ]] || { rm -rf -- "$stage"; die "Archive thiếu metadata/config/document-root."; }
  metadata_domain="$(sed -n 's/^domain=//p' "$stage/metadata" | head -n1)"
  document_root="$(sed -n 's/^document_root=//p' "$stage/metadata" | head -n1)"
  [[ "$metadata_domain" == "$domain" ]] || { rm -rf -- "$stage"; die "Domain trong archive không khớp: $metadata_domain"; }
  assert_abs_path "$document_root"
  if find "$stage/document-root" -type l -print -quit | grep -q .; then rm -rf -- "$stage"; die "Archive chứa symlink; từ chối restore."; fi
  confirm "Restore $domain vào $document_root từ $archive?" || { rm -rf -- "$stage"; die "Đã hủy."; }
  config="$(web_site_config "$domain")"; [[ -e "$config" ]] && backup="$(backup_file "$config" web)"
  mkdir -p "$document_root" "$(web_config_dir)"
  cp -a "$stage/document-root/." "$document_root/"
  install -m 0644 "$stage/config.conf" "$config"
  web_prepare_selinux_path "$document_root"
  if ! web_check; then
    [[ -n "$backup" ]] && restore_backup_now "$config" "$backup"
    rm -rf -- "$stage"; die "Cấu hình restore lỗi; đã rollback VirtualHost."
  fi
  rm -rf -- "$stage"
  log_ok "Đã restore website $domain."
}
