#!/usr/bin/env bash

set -euo pipefail

CONFIG_FILE="/etc/sysctl.d/99-ipv6-toggle.conf"

usage() {
  cat <<'EOF'
Usage:
  bash ipv6-toggle.sh
  bash ipv6-toggle.sh enable
  bash ipv6-toggle.sh disable

Options:
  enable   Enable IPv6
  disable  Disable IPv6
  help     Show this help message
EOF
}

print_error() {
  printf 'Error: %s\n' "$*" >&2
}

print_info() {
  printf '%s\n' "$*"
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    print_error "Required command not found: $1"
    exit 1
  fi
}

check_os() {
  if [[ ! -r /etc/os-release ]]; then
    print_error "Could not read /etc/os-release. This script is intended for Ubuntu 24.04."
    exit 1
  fi

  # shellcheck disable=SC1091
  . /etc/os-release

  if [[ "${ID:-}" != "ubuntu" || "${VERSION_ID:-}" != "24.04" ]]; then
    print_error "This script supports Ubuntu 24.04 only. Detected: ${PRETTY_NAME:-unknown system}"
    exit 1
  fi
}

run_privileged() {
  if [[ "${EUID}" -eq 0 ]]; then
    "$@"
    return
  fi

  if ! command -v sudo >/dev/null 2>&1; then
    print_error "Root privileges are required. Run the script as root or install sudo."
    exit 1
  fi

  sudo "$@"
}

build_config() {
  local value="$1"

  cat <<EOF
# Managed by ipv6-toggle.sh
net.ipv6.conf.all.disable_ipv6=${value}
net.ipv6.conf.default.disable_ipv6=${value}
net.ipv6.conf.lo.disable_ipv6=${value}
EOF
}

apply_config() {
  local action="$1"
  local value="$2"
  local temp_file

  temp_file="$(mktemp)"
  trap 'rm -f "$temp_file"' RETURN

  build_config "${value}" > "${temp_file}"

  run_privileged install -d /etc/sysctl.d
  run_privileged install -m 0644 "${temp_file}" "${CONFIG_FILE}"
  run_privileged sysctl -p "${CONFIG_FILE}" >/dev/null

  trap - RETURN
  rm -f "${temp_file}"

  print_info ""
  print_info "IPv6 ${action}."
  print_info "Config file: ${CONFIG_FILE}"
  print_info "Changes were applied immediately."
  print_info "If the server continues using old network state, reboot it to be safe."
}

disable_ipv6() {
  apply_config "disabled" "1"
}

enable_ipv6() {
  apply_config "enabled" "0"
}

prompt_action() {
  print_info "Select an action:"
  print_info "1) Disable IPv6"
  print_info "2) Enable IPv6"

  while true; do
    read -r -p "Enter 1 or 2: " choice

    case "${choice}" in
      1)
        disable_ipv6
        return
        ;;
      2)
        enable_ipv6
        return
        ;;
      *)
        print_error "Invalid choice. Please enter 1 or 2."
        ;;
    esac
  done
}

main() {
  local command="${1:-}"

  if [[ "${command}" == "help" || "${command}" == "-h" || "${command}" == "--help" ]]; then
    usage
    return
  fi

  if [[ "$#" -gt 1 ]]; then
    print_error "Too many arguments."
    usage
    exit 1
  fi

  case "${command}" in
    ""|enable|disable)
      ;;
    *)
      print_error "Unknown argument: ${command}"
      usage
      exit 1
      ;;
  esac

  require_command sysctl
  require_command install
  require_command mktemp
  check_os

  case "${command}" in
    "")
      prompt_action
      ;;
    enable)
      enable_ipv6
      ;;
    disable)
      disable_ipv6
      ;;
  esac
}

main "$@"
