#!/usr/bin/env bash

dns_network_command() {
  local action="${1:-list}"; shift || true
  require_command nmcli
  case "$action" in
    list) nmcli -f NAME,UUID,TYPE,DEVICE connection show ;;
    static)
      require_args 4 "$#" 'netadmin dns network static <connection> <cidr> <gateway> <dns[,dns]>'
      require_root; assert_cidr "$2"; assert_ipv4 "$3"
      local dns; IFS=',' read -r -a dns_values <<< "$4"; for dns in "${dns_values[@]}"; do assert_ipv4 "$dns"; done
      run nmcli connection modify "$1" ipv4.method manual ipv4.addresses "$2" ipv4.gateway "$3" ipv4.dns "${4//,/ }"
      run nmcli connection up "$1"
      ;;
    dhcp)
      require_args 1 "$#" 'netadmin dns network dhcp <connection>'; require_root
      run nmcli connection modify "$1" ipv4.method auto ipv4.addresses '' ipv4.gateway '' ipv4.dns ''
      run nmcli connection up "$1"
      ;;
    *) die "Network action không hỗ trợ: $action" ;;
  esac
}
