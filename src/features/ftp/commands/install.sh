#!/usr/bin/env bash

ftp_install() {
  require_root
  install_packages vsftpd lftp nmap-ncat openssl bind bind-utils firewalld policycoreutils libselinux-utils
  local config backup; config="$(ftp_config_path)"
  if [[ "${NETADMIN_DRY_RUN:-0}" == 1 && ! -e "$config" ]]; then
    log_info "Sẽ tạo baseline vsftpd, bật passive ports 30000-31000 và mở firewall sau khi cài package."
    service_action vsftpd enable-now
    firewall_add_service ftp
    log_info "Sẽ chuẩn bị và khởi động BIND để hỗ trợ FTP DNS."
    log_warn "FTP/vsftpd đã bị deprecate trên RHEL 10; chỉ nên dùng cho bài lab, ưu tiên SFTP/WebDAV cho hệ thống mới."
    return
  fi
  [[ -e "$config" ]] || die "Không tìm thấy cấu hình vsftpd sau khi cài: $config"
  backup="$(backup_file "$config" ftp)"
  ftp_set_option listen YES
  ftp_set_option listen_ipv6 NO
  ftp_set_option anonymous_enable NO
  ftp_set_option local_enable YES
  ftp_set_option write_enable YES
  ftp_set_option chroot_local_user YES
  ftp_set_option allow_writeable_chroot YES
  ftp_set_option no_anon_password YES
  ftp_set_option reverse_lookup_enable NO
  ftp_set_option pasv_min_port 30000
  ftp_set_option pasv_max_port 31000
  ftp_check || { restore_backup_now "$config" "$backup"; die "Cấu hình lỗi; đã rollback."; }
  service_action vsftpd enable-now
  firewall_add_service ftp
  if command_exists firewall-cmd && service_is_active firewalld; then
    run firewall-cmd --permanent --add-port=30000-31000/tcp
    run firewall-cmd --reload
  fi
  dns_ensure_managed_include
  dns_check
  service_action named enable-now
  firewall_add_service dns
  log_ok "Đã cài vsftpd với passive ports 30000-31000."
  log_warn "FTP/vsftpd đã bị deprecate trên RHEL 10; chỉ nên dùng cho bài lab, ưu tiên SFTP/WebDAV cho hệ thống mới."
}
