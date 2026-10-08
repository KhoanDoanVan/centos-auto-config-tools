#!/usr/bin/env bash

is_ipv4() {
  local ip="$1" octet IFS=.
  local -a parts
  read -r -a parts <<< "$ip"
  [[ ${#parts[@]} -eq 4 ]] || return 1
  for octet in "${parts[@]}"; do
    [[ "$octet" =~ ^[0-9]{1,3}$ ]] && (( 10#$octet <= 255 )) || return 1
  done
}

is_prefix() { [[ "$1" =~ ^[0-9]+$ ]] && (( 10#$1 >= 0 && 10#$1 <= 32 )); }
is_cidr() { local ip="${1%/*}" prefix="${1#*/}"; [[ "$1" == */* ]] && is_ipv4 "$ip" && is_prefix "$prefix"; }
is_mac() { [[ "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" =~ ^([0-9a-f]{2}:){5}[0-9a-f]{2}$ ]]; }
is_hostname() { [[ "$1" =~ ^[A-Za-z0-9]([A-Za-z0-9.-]{0,251}[A-Za-z0-9])?$ ]]; }
is_domain() { is_hostname "$1" && [[ "$1" == *.* ]]; }
is_identifier() { [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]{0,63}$ ]]; }
is_abs_path() { [[ "$1" == /* && "$1" != *$'\n'* ]]; }
is_uint() { [[ "$1" =~ ^[0-9]+$ ]]; }

assert_ipv4() { is_ipv4 "$1" || die "IPv4 không hợp lệ: $1"; }
assert_cidr() { is_cidr "$1" || die "CIDR không hợp lệ: $1"; }
assert_mac() { is_mac "$1" || die "MAC không hợp lệ: $1"; }
assert_hostname() { is_hostname "$1" || die "Hostname không hợp lệ: $1"; }
assert_domain() { is_domain "$1" || die "Domain không hợp lệ: $1"; }
assert_identifier() { is_identifier "$1" || die "Tên định danh không hợp lệ: $1"; }
assert_abs_path() { is_abs_path "$1" || die "Cần đường dẫn tuyệt đối hợp lệ: $1"; }
assert_uint() { is_uint "$1" || die "Cần số nguyên không âm: $1"; }

ipv4_to_int() {
  local IFS=. a b c d
  read -r a b c d <<< "$1"
  printf '%u\n' "$(( (10#$a << 24) + (10#$b << 16) + (10#$c << 8) + 10#$d ))"
}

ipv4_in_subnet() {
  local ip="$1" subnet="$2" mask="$3" ip_num subnet_num mask_num
  ip_num="$(ipv4_to_int "$ip")"; subnet_num="$(ipv4_to_int "$subnet")"; mask_num="$(ipv4_to_int "$mask")"
  (( (ip_num & mask_num) == (subnet_num & mask_num) ))
}

netmask_to_prefix() {
  local mask="$1" octet bits=0 seen_partial=0 value
  is_ipv4 "$mask" || return 1
  local IFS=.; local -a parts
  read -r -a parts <<< "$mask"
  for octet in "${parts[@]}"; do
    case "$octet" in 255) value=8;; 254) value=7;; 252) value=6;; 248) value=5;; 240) value=4;; 224) value=3;; 192) value=2;; 128) value=1;; 0) value=0;; *) return 1;; esac
    (( seen_partial == 0 )) || [[ "$value" -eq 0 ]] || return 1
    (( value < 8 )) && seen_partial=1
    bits=$((bits + value))
  done
  printf '%s\n' "$bits"
}
