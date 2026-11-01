#!/usr/bin/env bash

mail_test_command() {
  local protocol="${1:-}" host="${2:-127.0.0.1}" port
  assert_hostname "$host"
  case "$protocol" in
    smtp) port=25 ;;
    pop3) port=110 ;;
    imap) port=143 ;;
    *) die 'Cách dùng: netadmin mail test <smtp|pop3|imap> [host]' ;;
  esac
  require_command nc
  nc -zv -w 5 "$host" "$port"
  log_ok "$protocol phản hồi TCP tại $host:$port"
}
