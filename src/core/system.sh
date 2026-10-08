#!/usr/bin/env bash

run() {
  if [[ "${NETADMIN_DRY_RUN:-0}" == 1 ]]; then
    printf '[DRY-RUN] ' >&2; printf '%q ' "$@" >&2; printf '\n' >&2
    return 0
  fi
  "$@"
}

command_exists() { command -v "$1" >/dev/null 2>&1; }
require_command() { command_exists "$1" || die "Thiếu command: $1"; }

package_manager() {
  if command_exists dnf; then printf '%s\n' dnf
  elif command_exists yum; then printf '%s\n' yum
  else die "Chỉ hỗ trợ hệ thống dùng dnf hoặc yum."
  fi
}

install_packages() {
  require_root
  local manager; manager="$(package_manager)"
  run "$manager" install -y "$@"
}

service_action() {
  local service="$1" action="$2"
  require_root; require_command systemctl
  case "$action" in
    start|stop|restart|reload|status|enable|disable) run systemctl "$action" "$service" ;;
    enable-now) run systemctl enable --now "$service" ;;
    *) die "Service action không hỗ trợ: $action" ;;
  esac
}

service_is_active() { systemctl is-active --quiet "$1" 2>/dev/null; }

firewall_add_service() {
  local service="$1"
  if command_exists firewall-cmd && service_is_active firewalld; then
    run firewall-cmd --permanent --add-service="$service"
    run firewall-cmd --reload
  else
    log_warn "firewalld không hoạt động; bỏ qua mở service $service."
  fi
}

selinux_enable_boolean() {
  local key="$1"
  command_exists setsebool && run setsebool -P "$key" on || log_warn "Không có setsebool; bỏ qua $key."
}

write_stdin_file() {
  local destination="$1" mode="${2:-0644}" temporary
  ensure_parent_dir "$destination"
  temporary="$(mktemp)"
  cat > "$temporary"
  run install -m "$mode" "$temporary" "$destination"
  rm -f "$temporary"
}
