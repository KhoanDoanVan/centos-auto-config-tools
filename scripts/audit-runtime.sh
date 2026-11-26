#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$APP_ROOT"

missing=0
check_command() {
  local module="$1" command="$2"
  if command -v "$command" >/dev/null 2>&1; then
    printf '[OK]      %-10s %s\n' "$module" "$command"
  else
    printf '[MISSING] %-10s %s\n' "$module" "$command"
    missing=$((missing + 1))
  fi
}

printf 'NetAdmin runtime preflight (read-only)\n'
host_name='Unknown'
if [[ -r /etc/os-release ]]; then host_name="$(. /etc/os-release; printf '%s' "${PRETTY_NAME:-Unknown}")"; fi
printf 'Host: %s\n\n' "$host_name"

doctor_status=0
./bin/netadmin doctor run || doctor_status=$?
printf '\nDependency map:\n'
while read -r module command; do
  check_command "$module" "$command"
done <<'EOF'
core systemctl
core ip
dns nmcli
dns named-checkconf
dns named-checkzone
dns dig
dhcp dhcpd
dhcp omshell
storage lsblk
storage parted
storage findmnt
storage blkid
storage pvs
storage vgs
storage lvs
samba testparm
samba smbclient
samba mount.cifs
web apachectl
ftp openssl
ftp ss
mail postfix
mail doveconf
mail nc
ui cockpit-bridge
EOF

printf '\nRuntime preflight: doctor=%s, missing=%s\n' "$doctor_status" "$missing"
if (( doctor_status != 0 )); then
  printf 'Host này không phải môi trường nghiệm thu đầy đủ. Trên Ubuntu chỉ chạy audit-static.sh hoặc xem UI.\n' >&2
fi
(( doctor_status == 0 && missing == 0 ))
