#!/usr/bin/env bash
set -euo pipefail

# Refresh the hardware-configuration.nix for a host using nixos-generate-config.
# Usage: update-hardware.sh [host] [/path/to/hardware-configuration.nix]

HOST="${1:-nihilix}"
SOURCE_CONFIG="${2:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_PATH="${REPO_ROOT}/hosts/${HOST}/hardware-configuration.nix"

if [[ ! -d "${REPO_ROOT}/hosts/${HOST}" ]]; then
  echo "Error: host '${HOST}' not found under ${REPO_ROOT}/hosts." >&2
  exit 1
fi

if ! command -v nixos-generate-config >/dev/null 2>&1; then
  echo "Error: nixos-generate-config not found. Run this script inside a NixOS system or VM." >&2
  exit 1
fi

TMP_CONFIG="$(mktemp)"
trap 'rm -f "${TMP_CONFIG}"' EXIT

if [[ -n "${SOURCE_CONFIG}" ]]; then
  if [[ ! -f "${SOURCE_CONFIG}" ]]; then
    echo "Error: supplied config '${SOURCE_CONFIG}' does not exist." >&2
    exit 1
  fi
  cp "${SOURCE_CONFIG}" "${TMP_CONFIG}"
else
  sudo nixos-generate-config --show-hardware-config > "${TMP_CONFIG}"
fi

cp "${TMP_CONFIG}" "${TARGET_PATH}"

echo "hardware-configuration.nix updated at ${TARGET_PATH}"

echo "Rebuilding system using flake ${REPO_ROOT}#${HOST}..."
sudo nixos-rebuild switch --flake "${REPO_ROOT}#${HOST}"
