#!/usr/bin/env bash

dns_config_path() { system_path "${DNS_CONFIG:-/etc/named.conf}"; }
dns_managed_config_path() { system_path "${DNS_MANAGED_CONFIG:-/etc/named/netadmin-zones.conf}"; }
dns_zone_dir() { system_path "${DNS_ZONE_DIR:-/var/named}"; }

dns_zone_key() { printf '%s' "$1" | tr '.:/' '---'; }
dns_zone_file() { printf '%s/db.%s\n' "$(dns_zone_dir)" "$(dns_zone_key "$1")"; }

dns_ensure_managed_include() {
  local config managed include_line
  config="$(dns_config_path)"; managed="$(dns_managed_config_path)"
  include_line="include \"${DNS_MANAGED_CONFIG:-/etc/named/netadmin-zones.conf}\";"
  [[ -e "$config" ]] || die "Không tìm thấy named.conf: $config"
  if ! grep -Fqx "$include_line" "$config"; then
    backup_file "$config" dns >/dev/null
    if [[ "${NETADMIN_DRY_RUN:-0}" == 1 ]]; then log_info "Sẽ thêm include vào $config"
    else printf '\n%s\n' "$include_line" >> "$config"; fi
  fi
  [[ -e "$managed" ]] || write_stdin_file "$managed" <<'EOF'
// Managed by NetAdmin Toolkit. Do not edit managed blocks manually.
EOF
}

dns_remove_zone_block() {
  local zone="$1" config temporary
  config="$(dns_managed_config_path)"; temporary="$(mktemp)"
  awk -v begin="// NETADMIN:ZONE:$zone:BEGIN" -v end="// NETADMIN:ZONE:$zone:END" '
    $0==begin {skip=1; found=1; next} $0==end && skip {skip=0; next} !skip {print}
    END {if(!found) exit 4}
  ' "$config" > "$temporary" || { local status=$?; rm -f "$temporary"; return "$status"; }
  run install -m 0644 "$temporary" "$config"; rm -f "$temporary"
}

dns_check() {
  require_command named-checkconf
  run named-checkconf "$(dns_config_path)"
}

dns_zone_check() {
  require_command named-checkzone
  run named-checkzone "$1" "$(dns_zone_file "$1")"
}

dns_next_serial() { date +%Y%m%d00; }

dns_install_zone_file() {
  local temporary="$1" destination="$2"
  run install -o named -g named -m 0640 "$temporary" "$destination"
}
