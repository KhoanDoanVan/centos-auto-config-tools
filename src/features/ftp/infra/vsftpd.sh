#!/usr/bin/env bash

ftp_config_path() { system_path "${FTP_CONFIG:-/etc/vsftpd/vsftpd.conf}"; }
ftp_root_dir() { system_path "${FTP_ROOT:-/var/ftp}"; }
ftp_share_registry() { system_path "${FTP_SHARE_REGISTRY:-/etc/netadmin/ftp-shares.tsv}"; }
ftp_share_backup_dir() { system_path "${FTP_SHARE_BACKUP_DIR:-$NETADMIN_BACKUP_DIR/ftp-shares}"; }

ftp_set_option() {
  local key="$1" value="$2" config temporary
  config="$(ftp_config_path)"; temporary="$(mktemp)"
  awk -v key="$key" -v value="$value" '
    BEGIN {done=0}
    $0 ~ "^[[:space:]]*" key "=" {if(!done){print key "=" value; done=1}; next}
    {print}
    END {if(!done) print key "=" value}
  ' "$config" > "$temporary"
  run install -m 0600 "$temporary" "$config"; rm -f "$temporary"
}

ftp_check() {
  local config; config="$(ftp_config_path)"
  [[ -r "$config" ]] || die "Không đọc được cấu hình vsftpd: $config"
  awk '
    /^[[:space:]]*($|#)/ {next}
    !/^[A-Za-z0-9_]+=.*/ {printf "Dòng cấu hình không hợp lệ: %s\n", $0 > "/dev/stderr"; bad=1}
    END {exit bad}
  ' "$config" || die "Cấu hình vsftpd không hợp lệ."
  if grep -Eq '^listen=YES$' "$config" && grep -Eq '^listen_ipv6=YES$' "$config"; then
    die "listen và listen_ipv6 không thể đồng thời là YES."
  fi
  log_ok "Cấu hình vsftpd hợp lệ ở mức cú pháp cơ bản."
}

ftp_prepare_selinux_path() {
  local path="$1"
  if command_exists getenforce && [[ "$(getenforce)" != Disabled ]]; then
    if command_exists semanage; then
      semanage fcontext -a -t public_content_rw_t "${path}(/.*)?" 2>/dev/null || \
        semanage fcontext -m -t public_content_rw_t "${path}(/.*)?"
      run restorecon -Rv "$path"
    elif command_exists chcon; then
      run chcon -Rt public_content_rw_t "$path"
      log_warn "SELinux context được đặt bằng chcon và có thể mất sau relabel."
    fi
  fi
}

ftp_registry_add() {
  local name="$1" path="$2" mode="$3" registry
  registry="$(ftp_share_registry)"; ensure_parent_dir "$registry"
  [[ -e "$registry" ]] || write_stdin_file "$registry" 0644 <<'EOF'
# name	path	mode
EOF
  grep -q "^${name}[[:space:]]" "$registry" 2>/dev/null && die "FTP share đã tồn tại: $name"
  if [[ "${NETADMIN_DRY_RUN:-0}" == 1 ]]; then
    log_info "Sẽ ghi share $name vào $registry"
  else
    printf '%s\t%s\t%s\n' "$name" "$path" "$mode" >> "$registry"
  fi
}

ftp_registry_remove() {
  local name="$1" registry temporary
  registry="$(ftp_share_registry)"; [[ -r "$registry" ]] || return 4
  temporary="$(mktemp)"
  awk -v name="$name" 'BEGIN{found=0} $1==name{found=1;next} {print} END{if(!found)exit 4}' "$registry" > "$temporary" || {
    local status=$?; rm -f "$temporary"; return "$status"
  }
  run install -m 0644 "$temporary" "$registry"; rm -f "$temporary"
}

ftp_registry_lookup() {
  local name="$1" registry
  registry="$(ftp_share_registry)"; [[ -r "$registry" ]] || return 4
  awk -v name="$name" '$1==name {print $2 "\t" $3; found=1; exit} END{if(!found)exit 4}' "$registry"
}
