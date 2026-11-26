#!/usr/bin/env bash

doctor_command() {
  case "${1:-run}" in
    run)
      local failures=0 command os_name os_id_value os_version major
      printf '%-18s %s\n' 'CHECK' 'RESULT'
      os_name="$(os_release_value PRETTY_NAME 2>/dev/null || true)"
      os_id_value="$(os_id 2>/dev/null || true)"
      os_version="$(os_version_id 2>/dev/null || true)"
      major="${os_version%%.*}"
      printf '%-18s %s\n' 'OS' "${os_name:-Unknown}"
      printf '%-18s %s\n' 'Bash' "$BASH_VERSION"
      printf '%-18s %s\n' 'Privilege' "$([[ ${EUID:-1} -eq 0 ]] && echo root || echo non-root)"
      for command in awk grep sed install systemctl ip; do
        if command_exists "$command"; then printf '%-18s %s\n' "$command" OK
        else printf '%-18s %s\n' "$command" MISSING; failures=$((failures + 1)); fi
      done
      if is_rhel_family; then
        if [[ "$major" =~ ^[0-9]+$ ]] && (( major >= 10 )); then
          printf '%-18s %s\n' 'Runtime support' 'PARTIAL - ISC DHCP đã bị gỡ; DHCP cần hệ RHEL < 10'
          failures=$((failures + 1))
        else
          printf '%-18s %s\n' 'Runtime support' 'SUPPORTED - RHEL family < 10 (ưu tiên Rocky/Alma 9)'
        fi
      elif [[ "$os_id_value" =~ ^(ubuntu|debian)$ ]]; then
        printf '%-18s %s\n' 'Runtime support' 'UNSUPPORTED - chỉ chạy scripts/audit-static.sh trên máy này'
        failures=$((failures + 1))
      else
        printf '%-18s %s\n' 'Runtime support' 'UNSUPPORTED/UNKNOWN'
        failures=$((failures + 1))
      fi
      (( failures == 0 )) || return 1
      ;;
    help|-h|--help) echo 'Cách dùng: netadmin doctor [run]' ;;
    *) die "Doctor command không hỗ trợ: $1" ;;
  esac
}
