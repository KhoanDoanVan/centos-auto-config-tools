#!/usr/bin/env bash

dhcp_config_command() {
  local action="${1:-show}" config; config="$(dhcp_config_path)"
  case "$action" in
    show) cat "$config" ;;
    check) dhcp_check; log_ok 'Cấu hình DHCP hợp lệ.' ;;
    rollback) require_root; restore_latest_backup "$config" dhcp; dhcp_check ;;
    *) die "Config action không hỗ trợ: $action" ;;
  esac
}

dhcp_lease_command() {
  local action="${1:-list}" leases; shift || true; leases="$(dhcp_lease_path)"
  case "$action" in
    list)
      [[ -r "$leases" ]] || die "Không đọc được lease file: $leases"
      awk '/^lease /{ip=$2} /starts /{start=$3" "$4} /ends /{end=$3" "$4} /client-hostname /{host=$2; gsub(/[";]/,"",host)} /^}/{if(ip){printf "%-16s %-22s %-22s %s\n",ip,start,end,host; ip=start=end=host=""}}' "$leases"
      ;;
    release)
      require_args 1 "$#" 'netadmin dhcp lease release <ip>'; require_root; assert_ipv4 "$1"
      require_command omshell
      printf 'server localhost\nport 7911\nconnect\nnew lease\nset ip-address = %s\nopen\nremove\n' "$1" | run omshell
      ;;
    *) die "Lease action không hỗ trợ: $action" ;;
  esac
}
