#!/usr/bin/env bash

confirm() {
  local message="$1" answer
  if [[ "${NETADMIN_ASSUME_YES:-0}" == 1 ]]; then return 0; fi
  [[ -t 0 ]] || die "$message (cần terminal tương tác hoặc NETADMIN_ASSUME_YES=1)"
  read -r -p "$message [y/N]: " answer
  [[ "$answer" =~ ^[Yy]$ ]]
}

confirm_destructive() {
  local target="$1" answer
  [[ -t 0 ]] || die "Tác vụ phá huỷ cần terminal tương tác."
  log_warn "Thao tác có thể làm mất dữ liệu trên: $target"
  read -r -p "Nhập chính xác '$target' để tiếp tục: " answer
  [[ "$answer" == "$target" ]] || die "Đã hủy thao tác."
}
