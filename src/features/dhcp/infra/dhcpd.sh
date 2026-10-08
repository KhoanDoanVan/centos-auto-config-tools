#!/usr/bin/env bash

dhcp_config_path() { system_path "${DHCP_CONFIG:-/etc/dhcp/dhcpd.conf}"; }
dhcp_lease_path() { system_path "${DHCP_LEASES:-/var/lib/dhcpd/dhcpd.leases}"; }

dhcp_ensure_config() {
  local config; config="$(dhcp_config_path)"
  [[ -e "$config" ]] && return 0
  write_stdin_file "$config" <<'EOF'
# Managed in part by NetAdmin Toolkit.
authoritative;
ddns-update-style none;
default-lease-time 600;
max-lease-time 7200;
EOF
}

dhcp_remove_block() {
  local type="$1" name="$2" config temporary
  config="$(dhcp_config_path)"; temporary="$(mktemp)"
  awk -v begin="# NETADMIN:$type:$name:BEGIN" -v end="# NETADMIN:$type:$name:END" '
    $0 == begin { skip=1; found=1; next }
    $0 == end && skip { skip=0; next }
    !skip { print }
    END { if (!found) exit 4 }
  ' "$config" > "$temporary" || { local status=$?; rm -f "$temporary"; return "$status"; }
  run install -m 0644 "$temporary" "$config"
  rm -f "$temporary"
}

dhcp_append_block() {
  local config; config="$(dhcp_config_path)"
  if [[ "${NETADMIN_DRY_RUN:-0}" == 1 ]]; then
    log_info "Sẽ thêm block vào $config"; cat >/dev/null; return
  fi
  cat >> "$config"
}

dhcp_check() {
  local config; config="$(dhcp_config_path)"
  require_command dhcpd
  run dhcpd -t -cf "$config"
}

dhcp_commit() {
  dhcp_check
  if service_is_active dhcpd; then service_action dhcpd restart; fi
}
