#!/usr/bin/env sh
set -eu

: "${TECHNITIUM_ACME_DOMAIN:?TECHNITIUM_ACME_DOMAIN is required}"
: "${TECHNITIUM_PFX_TARGET:?TECHNITIUM_PFX_TARGET is required}"
: "${CERT_PATH:?CERT_PATH is required by the acme.sh reload hook}"

source_pfx="$(dirname "${CERT_PATH}")/${TECHNITIUM_ACME_DOMAIN}.pfx"
target_dir="$(dirname "${TECHNITIUM_PFX_TARGET}")"
tmp_pfx="${TECHNITIUM_PFX_TARGET}.tmp"

if [ ! -s "${source_pfx}" ]; then
  echo "Technitium ACME deploy hook: PKCS#12 file not found: ${source_pfx}" >&2
  exit 1
fi

mkdir -p "${target_dir}"
cp "${source_pfx}" "${tmp_pfx}"
chmod 0600 "${tmp_pfx}"
mv -f "${tmp_pfx}" "${TECHNITIUM_PFX_TARGET}"

echo "Technitium ACME deploy hook: updated ${TECHNITIUM_PFX_TARGET}"
