#!/usr/bin/env bash

samba_config_path() { system_path "${SAMBA_CONFIG:-/etc/samba/smb.conf}"; }

samba_ensure_config() {
  local config; config="$(samba_config_path)"
  [[ -e "$config" ]] && return
  write_stdin_file "$config" <<'EOF'
[global]
  workgroup = WORKGROUP
  security = user
  map to guest = Bad User
  logging = file
  log file = /var/log/samba/%m.log
EOF
}

samba_remove_share_block() {
  local name="$1" config temporary
  config="$(samba_config_path)"; temporary="$(mktemp)"
  awk -v begin="# NETADMIN:SHARE:$name:BEGIN" -v end="# NETADMIN:SHARE:$name:END" '
    $0==begin {skip=1; found=1; next} $0==end && skip {skip=0; next} !skip {print}
    END {if(!found) exit 4}
  ' "$config" > "$temporary" || { local s=$?; rm -f "$temporary"; return "$s"; }
  run install -m 0644 "$temporary" "$config"; rm -f "$temporary"
}

samba_check() { require_command testparm; run testparm -s "$(samba_config_path)" >/dev/null; }

samba_prepare_selinux_path() {
  local path="$1"
  if command_exists getenforce && [[ "$(getenforce)" != Disabled ]]; then
    if command_exists semanage; then
      semanage fcontext -a -t samba_share_t "${path}(/.*)?" 2>/dev/null || semanage fcontext -m -t samba_share_t "${path}(/.*)?"
      run restorecon -Rv "$path"
    elif command_exists chcon; then
      run chcon -Rt samba_share_t "$path"
      log_warn "SELinux context được đặt bằng chcon (không bền qua relabel)."
    fi
  fi
}
