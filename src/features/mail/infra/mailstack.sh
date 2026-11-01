#!/usr/bin/env bash

mail_postfix_config() { system_path "${MAIL_POSTFIX_CONFIG:-/etc/postfix/main.cf}"; }
mail_dovecot_config() { system_path "${MAIL_DOVECOT_CONFIG:-/etc/dovecot/conf.d/99-netadmin.conf}"; }

mail_check() {
  require_command postfix; require_command doveconf
  run postfix check
  run doveconf -c "$(system_path /etc/dovecot/dovecot.conf)" -n >/dev/null
}

mail_write_dovecot_config() {
  local config; config="$(mail_dovecot_config)"
  write_stdin_file "$config" 0644 <<'EOF'
# Managed by NetAdmin Toolkit.
protocols = imap pop3
mail_location = maildir:~/Maildir
auth_mechanisms = plain login

# Lab mode permits password authentication without TLS on trusted networks.
# Use TLS and set this to yes before exposing the server publicly.
disable_plaintext_auth = no

# Postfix uses this private socket for SMTP AUTH through Dovecot.
service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0660
    user = postfix
    group = postfix
  }
}
EOF
}
