#!/usr/bin/env bash

doctor_command() {
  case "${1:-run}" in
    run)
      local failures=0 command
      printf '%-18s %s\n' 'CHECK' 'RESULT'
      printf '%-18s %s\n' 'OS' "$(. /etc/os-release 2>/dev/null; printf '%s %s' "${NAME:-Unknown}" "${VERSION_ID:-}")"
      printf '%-18s %s\n' 'Bash' "$BASH_VERSION"
      printf '%-18s %s\n' 'Privilege' "$([[ ${EUID:-1} -eq 0 ]] && echo root || echo non-root)"
      for command in awk grep sed install systemctl ip; do
        if command_exists "$command"; then printf '%-18s %s\n' "$command" OK
        else printf '%-18s %s\n' "$command" MISSING; failures=$((failures + 1)); fi
      done
      (( failures == 0 )) || return 1
      ;;
    help|-h|--help) echo 'Cách dùng: netadmin doctor [run]' ;;
    *) die "Doctor command không hỗ trợ: $1" ;;
  esac
}
