#!/usr/bin/env bash

dns_resolve_connection() {
  local target="$1" connection
  if nmcli -g NAME connection show "$target" >/dev/null 2>&1; then
    printf '%s\n' "$target"
    return 0
  fi
  if nmcli device show "$target" >/dev/null 2>&1; then
    connection="$(nmcli -g GENERAL.CONNECTION device show "$target" 2>/dev/null | head -n1)"
    [[ -n "$connection" && "$connection" != '--' ]] && { printf '%s\n' "$connection"; return 0; }
    die "Card mạng '$target' chưa có connection profile đang hoạt động. Hãy tạo hoặc kích hoạt profile trước."
  fi
  die "Không tìm thấy connection hoặc card mạng '$target'. Hãy chạy 'netadmin dns network list' để lấy tên chính xác."
}

dns_network_command() {
  local action="${1:-list}"; shift || true
  require_command nmcli
  case "$action" in
    list) nmcli -f NAME,UUID,TYPE,DEVICE connection show ;;
    static)
      require_args 4 "$#" 'netadmin dns network static <connection> <cidr> <gateway> <dns[,dns]>'
      require_root; assert_cidr "$2"; assert_ipv4 "$3"
      local dns connection; IFS=',' read -r -a dns_values <<< "$4"; for dns in "${dns_values[@]}"; do assert_ipv4 "$dns"; done
      connection="$(dns_resolve_connection "$1")"
      [[ "$connection" == "$1" ]] || log_info "Đã ánh xạ card '$1' sang connection '$connection'."
      run nmcli connection modify "$connection" ipv4.method manual ipv4.addresses "$2" ipv4.gateway "$3" ipv4.dns "${4//,/ }"
      run nmcli connection up "$connection"
      ;;
    dhcp)
      require_args 1 "$#" 'netadmin dns network dhcp <connection>'; require_root
      local connection; connection="$(dns_resolve_connection "$1")"
      [[ "$connection" == "$1" ]] || log_info "Đã ánh xạ card '$1' sang connection '$connection'."
      run nmcli connection modify "$connection" ipv4.method auto ipv4.addresses '' ipv4.gateway '' ipv4.dns ''
      run nmcli connection up "$connection"
      ;;
    *) die "Network action không hỗ trợ: $action" ;;
  esac
}
