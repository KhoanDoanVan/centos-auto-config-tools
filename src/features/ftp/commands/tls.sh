#!/usr/bin/env bash

ftp_tls_command() {
  local action="${1:-status}"; shift || true
  case "$action" in
    configure) require_args 2 "$#" 'netadmin ftp tls configure <certificate> <private-key>'; ftp_tls_configure "$1" "$2" ;;
    disable) ftp_tls_disable ;;
    status) grep -E '^(ssl_enable|rsa_cert_file|rsa_private_key_file|force_local_(logins|data)_ssl)=' "$(ftp_config_path)" || true ;;
    *) die "FTP TLS action không hỗ trợ: $action" ;;
  esac
}

ftp_tls_configure() {
  local certificate="$1" private_key="$2" config backup
  require_root; assert_abs_path "$certificate"; assert_abs_path "$private_key"
  [[ -r "$certificate" && -r "$private_key" ]] || die 'Không đọc được certificate hoặc private key.'
  require_command openssl
  openssl x509 -in "$certificate" -noout >/dev/null || die 'Certificate X.509 không hợp lệ.'
  openssl pkey -in "$private_key" -noout >/dev/null || die 'Private key không hợp lệ.'
  config="$(ftp_config_path)"; backup="$(backup_file "$config" ftp)"
  ftp_set_option ssl_enable YES
  ftp_set_option rsa_cert_file "$certificate"
  ftp_set_option rsa_private_key_file "$private_key"
  ftp_set_option allow_anon_ssl NO
  ftp_set_option force_local_logins_ssl YES
  ftp_set_option force_local_data_ssl YES
  ftp_set_option ssl_sslv2 NO
  ftp_set_option ssl_sslv3 NO
  ftp_set_option ssl_tlsv1 YES
  ftp_check || { restore_backup_now "$config" "$backup"; die 'Cấu hình TLS lỗi; đã rollback.'; }
  log_ok 'Đã bật TLS bắt buộc cho local FTP users.'
}

ftp_tls_disable() {
  local config backup
  require_root; config="$(ftp_config_path)"; backup="$(backup_file "$config" ftp)"
  ftp_set_option ssl_enable NO
  ftp_check || { restore_backup_now "$config" "$backup"; die 'Không thể tắt TLS; đã rollback.'; }
  log_ok 'Đã tắt FTP TLS.'
}
