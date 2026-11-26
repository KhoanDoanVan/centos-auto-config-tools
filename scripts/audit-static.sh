#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$APP_ROOT"

failures=0
section() { printf '\n== %s ==\n' "$1"; }
pass() { printf '[OK] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1" >&2; failures=$((failures + 1)); }

section 'Bash syntax'
while IFS= read -r file; do
  if bash -n "$file"; then pass "$file"; else fail "$file"; fi
done < <(printf '%s\n' bin/netadmin; find src scripts -type f -name '*.sh' -print | sort)

section 'JavaScript syntax and UI catalog'
if command -v node >/dev/null 2>&1; then
  node --check site/dist/app.js && pass 'site/dist/app.js syntax' || fail 'site/dist/app.js syntax'
  node scripts/audit-ui-catalog.mjs && pass '123 UI tools map to supported CLI routes' || fail 'UI/CLI catalog mapping'
else
  fail 'Thiếu node; cần Node.js để audit catalog Cockpit'
fi

section 'CLI dispatch'
for module in doctor dhcp dns storage samba web ftp mail ui; do
  if ./bin/netadmin "$module" help >/dev/null; then pass "netadmin $module help"; else fail "netadmin $module help"; fi
done

section 'Safety invariants'
if rg -n '^[[:space:]]*semanage[[:space:]]' src/features >/dev/null; then
  rg -n '^[[:space:]]*semanage[[:space:]]' src/features >&2
  fail 'Feature gọi semanage trực tiếp, có thể bỏ qua Dry run'
else
  pass 'Không có mutation SELinux trực tiếp trong feature'
fi
if rg -F "window.cockpit.spawn(['/usr/local/bin/netadmin'" site/dist/app.js >/dev/null && \
   rg -n 'ln -sfn "\$runtime_dir/bin/netadmin" "\$cli_link"' src/features/ui/module.sh >/dev/null; then
  pass 'Cockpit runtime path khớp CLI symlink'
else
  fail 'Cockpit runtime path không khớp UI installer'
fi

section 'Optional lint'
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck_status=0
  while IFS= read -r file; do shellcheck -x "$file" || shellcheck_status=1; done \
    < <(printf '%s\n' bin/netadmin; find src scripts -type f -name '*.sh' -print | sort)
  if (( shellcheck_status == 0 )); then pass 'shellcheck'; else fail 'shellcheck'; fi
else
  printf '[WARN] shellcheck chưa cài; bỏ qua lint tùy chọn.\n'
fi

printf '\nStatic audit: %s failure(s).\n' "$failures"
(( failures == 0 ))
