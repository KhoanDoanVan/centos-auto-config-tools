#!/usr/bin/env bash

mail_configure() {
  require_args 3 "$#" 'netadmin mail configure <domain> <server-fqdn> <trusted-network-cidr>'
  require_root
  [[ -z "${NETADMIN_ROOT:-}" ]] || die "Không hỗ trợ postconf bên trong NETADMIN_ROOT."
  local domain="$1" fqdn="$2" network="$3" postfix_config dovecot_config postfix_backup dovecot_backup=''
  assert_domain "$domain"; assert_hostname "$fqdn"; assert_cidr "$network"
  [[ "$fqdn" == *".$domain" || "$fqdn" == "$domain" ]] || die "FQDN phải thuộc domain $domain"
  require_command postconf
  postfix_config="$(mail_postfix_config)"; dovecot_config="$(mail_dovecot_config)"
  [[ -e "$postfix_config" ]] || die "Không tìm thấy Postfix config: $postfix_config"
  postfix_backup="$(backup_file "$postfix_config" mail)"
  [[ -e "$dovecot_config" ]] && dovecot_backup="$(backup_file "$dovecot_config" mail)"
  run postconf -e "myhostname = $fqdn"
  run postconf -e "mydomain = $domain"
  run postconf -e 'myorigin = $mydomain'
  run postconf -e 'inet_interfaces = all'
  run postconf -e 'inet_protocols = ipv4'
  run postconf -e "mynetworks = $network, 127.0.0.0/8"
  run postconf -e 'mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain'
  run postconf -e 'home_mailbox = Maildir/'
  run postconf -e 'smtpd_sasl_auth_enable = yes'
  run postconf -e 'smtpd_sasl_type = dovecot'
  run postconf -e 'smtpd_sasl_path = private/auth'
  run postconf -e 'smtpd_sasl_security_options = noanonymous'
  run postconf -e 'smtpd_relay_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination'
  mail_write_dovecot_config
  if ! mail_check; then
    restore_backup_now "$postfix_config" "$postfix_backup"
    if [[ -n "$dovecot_backup" ]]; then restore_backup_now "$dovecot_config" "$dovecot_backup"; else run rm -f -- "$dovecot_config"; fi
    die "Cấu hình mail lỗi; đã rollback."
  fi
  log_ok "Đã cấu hình mail server $fqdn cho domain $domain"
  log_info "Hãy tạo DNS A record cho $fqdn và MX record cho $domain bằng module dns."
}
