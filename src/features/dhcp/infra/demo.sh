#!/usr/bin/env bash

dhcp_isc_unsupported() {
  local version major
  is_rhel_family || return 1
  version="$(os_version_id 2>/dev/null || true)"
  major="${version%%.*}"
  [[ "$major" =~ ^[0-9]+$ ]] && (( major >= 10 ))
}

dhcp_demo_finish() {
  printf '\n[DRY-RUN] Dữ liệu mô phỏng DHCP trên CentOS 10; hệ thống chưa được thay đổi.\n'
}

dhcp_demo_scope() {
  local action="${1:-list}"; shift || true
  case "$action" in
    list)
      printf '%-14s %-18s %-31s %-15s %-15s %s\n' 'NAME' 'SUBNET' 'RANGE' 'GATEWAY' 'DNS' 'DOMAIN'
      printf '%-14s %-18s %-31s %-15s %-15s %s\n' 'lab' '192.168.10.0/24' '192.168.10.100-192.168.10.200' '192.168.10.1' '192.168.10.2' 'lab.local'
      ;;
    add|update)
      require_args 7 "$#" "netadmin dhcp scope $action <name> <subnet> <netmask> <start> <end> <gateway> <dns[,dns]> [domain] [lease]"
      assert_identifier "$1"; assert_ipv4 "$2"; netmask_to_prefix "$3" >/dev/null || die "Netmask không hợp lệ: $3"
      assert_ipv4 "$4"; assert_ipv4 "$5"; assert_ipv4 "$6"
      local dns; IFS=',' read -r -a dns_values <<< "$7"; for dns in "${dns_values[@]}"; do assert_ipv4 "$dns"; done
      [[ -z "${8:-}" ]] || assert_domain "$8"
      [[ -z "${9:-}" ]] || assert_uint "$9"
      printf 'Scope %-12s : %s\nSubnet/Netmask    : %s / %s\nRange             : %s - %s\nGateway           : %s\nDNS               : %s\nDomain            : %s\nLease             : %s seconds\n' \
        "$action" "$1" "$2" "$3" "$4" "$5" "$6" "$7" "${8:-lab.local}" "${9:-600}"
      printf 'Configuration test: OK\n'
      ;;
    remove)
      require_args 1 "$#" 'netadmin dhcp scope remove <name>'; assert_identifier "$1"
      printf 'Removed scope: %s\nConfiguration test: OK\n' "$1"
      ;;
    *) die "Scope action không hỗ trợ: $action" ;;
  esac
}

dhcp_demo_reservation() {
  local action="${1:-list}"; shift || true
  case "$action" in
    list)
      printf '%-16s %-20s %-16s %s\n' 'NAME' 'MAC ADDRESS' 'FIXED IP' 'HOSTNAME'
      printf '%-16s %-20s %-16s %s\n' 'server01' '00:50:56:aa:10:10' '192.168.10.10' 'server01'
      printf '%-16s %-20s %-16s %s\n' 'printer01' '00:50:56:aa:10:20' '192.168.10.20' 'printer01'
      ;;
    add)
      require_args 3 "$#" 'netadmin dhcp reservation add <name> <mac> <ip> [hostname]'
      assert_identifier "$1"; assert_mac "$2"; assert_ipv4 "$3"; [[ -z "${4:-}" ]] || assert_hostname "$4"
      printf 'Reservation added: %s -> %s (%s)\nConfiguration test: OK\n' "$1" "$3" "$2"
      ;;
    remove)
      require_args 1 "$#" 'netadmin dhcp reservation remove <name>'; assert_identifier "$1"
      printf 'Reservation removed: %s\nConfiguration test: OK\n' "$1"
      ;;
    *) die "Reservation action không hỗ trợ: $action" ;;
  esac
}

dhcp_demo_lease() {
  local action="${1:-list}"; shift || true
  case "$action" in
    list)
      printf '%-16s %-20s %-20s %-18s %s\n' 'IP ADDRESS' 'STARTS' 'ENDS' 'HOSTNAME' 'STATE'
      printf '%-16s %-20s %-20s %-18s %s\n' '192.168.10.101' '2026/11/27 00:05' '2026/11/28 00:05' 'client01' 'active'
      printf '%-16s %-20s %-20s %-18s %s\n' '192.168.10.102' '2026/11/27 00:08' '2026/11/28 00:08' 'client02' 'active'
      ;;
    release)
      require_args 1 "$#" 'netadmin dhcp lease release <ip>'; assert_ipv4 "$1"
      printf 'Lease released: %s\n' "$1"
      ;;
    *) die "Lease action không hỗ trợ: $action" ;;
  esac
}

dhcp_demo_config() {
  local action="${1:-show}"
  case "$action" in
    show)
      cat <<'EOF'
# Managed in part by NetAdmin Toolkit.
authoritative;
ddns-update-style none;
default-lease-time 86400;
max-lease-time 1036800;

# NETADMIN:SCOPE:lab:BEGIN
subnet 192.168.10.0 netmask 255.255.255.0 {
  range 192.168.10.100 192.168.10.200;
  option routers 192.168.10.1;
  option domain-name "lab.local";
  option domain-name-servers 192.168.10.2;
}
# NETADMIN:SCOPE:lab:END
EOF
      ;;
    check) printf 'Internet Systems Consortium DHCP configuration test: OK\n' ;;
    rollback) printf 'Restored latest DHCP configuration backup.\nConfiguration test: OK\n' ;;
    *) die "Config action không hỗ trợ: $action" ;;
  esac
}

dhcp_demo_command() {
  local command="$1"; shift || true
  case "$command" in
    install) printf 'Dependencies resolved.\nPackage dhcp-server prepared.\nService dhcpd enabled.\nFirewall service dhcp configured.\n' ;;
    scope) dhcp_demo_scope "$@" ;;
    reservation) dhcp_demo_reservation "$@" ;;
    lease) dhcp_demo_lease "$@" ;;
    config) dhcp_demo_config "$@" ;;
    service)
      require_args 1 "$#" 'netadmin dhcp service <action>'
      case "$1" in
        status) printf 'dhcpd.service - DHCPv4 Server\n   Loaded: loaded; enabled\n   Active: active (running)\n   Listening: UDP 0.0.0.0:67\n' ;;
        start|stop|restart|reload|enable|disable|enable-now) printf 'Service action completed: dhcpd %s\n' "$1" ;;
        *) die "Service action không hỗ trợ: $1" ;;
      esac
      ;;
    *) die "DHCP demo command không hỗ trợ: $command" ;;
  esac
  dhcp_demo_finish
}
