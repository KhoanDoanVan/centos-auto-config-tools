#!/usr/bin/env bash

run() {
  if [[ "${NETADMIN_DRY_RUN:-0}" == 1 ]]; then
    printf '[DRY-RUN] ' >&2; printf '%q ' "$@" >&2; printf '\n' >&2
    return 0
  fi
  "$@"
}

is_dry_run() { [[ "${NETADMIN_DRY_RUN:-0}" == 1 ]]; }

os_release_value() {
  local key="$1"
  [[ -r /etc/os-release ]] || return 1
  ( . /etc/os-release; printf '%s\n' "${!key:-}" )
}

os_id() { os_release_value ID; }
os_id_like() { os_release_value ID_LIKE; }
os_version_id() { os_release_value VERSION_ID; }

is_rhel_family() {
  local id like
  id="$(os_id 2>/dev/null || true)"
  like="$(os_id_like 2>/dev/null || true)"
  [[ "$id" =~ ^(rhel|centos|rocky|almalinux|ol|fedora)$ || " $like " == *" rhel "* || " $like " == *" fedora "* ]]
}

command_exists() { command -v "$1" >/dev/null 2>&1; }
require_command() { command_exists "$1" || die "Thiếu command: $1"; }

require_command_after_install() {
  local command="$1" install_step="$2"
  command_exists "$command" || \
    die "Thiếu command '$command'. Hãy tắt Dry run và chạy '$install_step' trước, sau đó thử lại."
}

package_manager() {
  if command_exists dnf; then printf '%s\n' dnf
  elif command_exists yum; then printf '%s\n' yum
  else die "Runtime hiện chỉ hỗ trợ hệ RHEL dùng dnf/yum. Trên Ubuntu chỉ chạy audit tĩnh; không chạy install/config thật."
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

selinux_set_file_context() {
  local path="$1" context="$2" expression="${1}(/.*)?"
  command_exists getenforce || return 0
  [[ "$(getenforce)" != Disabled ]] || return 0
  if command_exists semanage; then
    if is_dry_run; then
      run semanage fcontext -a -t "$context" "$expression"
    else
      semanage fcontext -a -t "$context" "$expression" 2>/dev/null || \
        semanage fcontext -m -t "$context" "$expression"
    fi
    command_exists restorecon && run restorecon -Rv "$path"
  elif command_exists chcon; then
    run chcon -Rt "$context" "$path"
    log_warn "SELinux context được đặt bằng chcon và có thể mất sau relabel."
  else
    log_warn "Thiếu semanage/chcon; chưa thể đặt SELinux context $context cho $path."
  fi
}

write_stdin_file() {
  local destination="$1" mode="${2:-0644}" temporary
  ensure_parent_dir "$destination"
  temporary="$(mktemp)"
  cat > "$temporary"
  run install -m "$mode" "$temporary" "$destination"
  rm -f "$temporary"
}
