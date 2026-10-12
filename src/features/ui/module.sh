#!/usr/bin/env bash

ui_help() {
  cat <<'EOF'
Cách dùng: netadmin ui <command>

  install    Cài/cập nhật NetAdmin Tools vào Cockpit
  status     Kiểm tra Cockpit và package NetAdmin
  uninstall  Gỡ giao diện Cockpit (không gỡ CLI và cấu hình dịch vụ)
EOF
}

ui_install() {
  require_root
  local source_dir="$APP_ROOT/site/dist"
  local package_dir="/usr/local/share/cockpit/netadmin"
  local runtime_dir="/opt/netadmin"
  local cli_link="/usr/local/bin/netadmin"

  [[ -f "$source_dir/manifest.json" && -f "$source_dir/index.html" ]] || \
    die "Thiếu Cockpit package tại: $source_dir"

  if ! command_exists cockpit-bridge; then
    log_info "Đang cài Cockpit..."
    install_packages cockpit
  fi

  run install -d -m 0755 "$package_dir"
  run cp -a "$source_dir/." "$package_dir/"
  [[ "$runtime_dir" == /opt/netadmin ]] || die "Runtime path không an toàn"
  run install -d -m 0755 "$runtime_dir"
  run rm -rf -- "$runtime_dir/bin" "$runtime_dir/src"
  run cp -a "$APP_ROOT/bin" "$APP_ROOT/src" "$runtime_dir/"
  run install -d -m 0755 "$runtime_dir/config"
  if [[ ! -e "$runtime_dir/config/netadmin.conf.example" ]]; then
    run install -m 0644 "$APP_ROOT/config/netadmin.conf.example" "$runtime_dir/config/netadmin.conf.example"
  fi
  run ln -sfn "$runtime_dir/bin/netadmin" "$cli_link"
  run systemctl enable --now cockpit.socket
  firewall_add_service cockpit

  if [[ "${NETADMIN_DRY_RUN:-0}" != 1 ]]; then
    cockpit-bridge --packages 2>/dev/null | grep -q 'netadmin' || \
      log_warn "Cockpit chưa liệt kê package netadmin; hãy đăng xuất/đăng nhập lại."
  fi

  log_ok "Đã cài NetAdmin Cockpit UI."
  log_info "Mở: https://<IP-CENTOS>:9090 và chọn 'NetAdmin Tools'."
}

ui_status() {
  local package_dir="/usr/local/share/cockpit/netadmin"
  printf '%-22s %s\n' 'Cockpit socket' "$(systemctl is-active cockpit.socket 2>/dev/null || true)"
  printf '%-22s %s\n' 'Cockpit package' "$([[ -f "$package_dir/manifest.json" ]] && echo installed || echo missing)"
  printf '%-22s %s\n' 'NetAdmin CLI' "$([[ -x /usr/local/bin/netadmin ]] && echo /usr/local/bin/netadmin || echo missing)"
  if command_exists cockpit-bridge; then
    printf '%-22s %s\n' 'Package registry' "$(cockpit-bridge --packages 2>/dev/null | grep -q 'netadmin' && echo detected || echo not-detected)"
  fi
}

ui_uninstall() {
  require_root
  local package_dir="/usr/local/share/cockpit/netadmin"
  [[ "$package_dir" == /usr/local/share/cockpit/netadmin ]] || die "Package path không an toàn"
  run rm -rf -- "$package_dir"
  if [[ -L /usr/local/bin/netadmin && "$(readlink /usr/local/bin/netadmin)" == /opt/netadmin/bin/netadmin ]]; then
    run rm -f -- /usr/local/bin/netadmin
  fi
  log_ok "Đã gỡ giao diện NetAdmin khỏi Cockpit."
}

ui_command() {
  local command="${1:-help}"; shift || true
  case "$command" in
    install|update) ui_install "$@" ;;
    status) ui_status "$@" ;;
    uninstall) ui_uninstall "$@" ;;
    help|-h|--help) ui_help ;;
    *) ui_help; die "UI command không hỗ trợ: $command" ;;
  esac
}
