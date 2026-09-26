#!/usr/bin/env sh
set -eu

: "${TECHNITIUM_ACME_EXPORT_DIR:?TECHNITIUM_ACME_EXPORT_DIR is required}"
: "${TECHNITIUM_PFX_PASSWORD:?TECHNITIUM_PFX_PASSWORD is required}"
: "${TECHNITIUM_PFX_TARGET:?TECHNITIUM_PFX_TARGET is required}"

cert_file="${TECHNITIUM_ACME_EXPORT_DIR}/cert.pem"
key_file="${TECHNITIUM_ACME_EXPORT_DIR}/key.pem"
ca_file="${TECHNITIUM_ACME_EXPORT_DIR}/ca.pem"
target_dir="$(dirname "${TECHNITIUM_PFX_TARGET}")"
tmp_pfx="${TECHNITIUM_PFX_TARGET}.tmp"

for file in "${cert_file}" "${key_file}" "${ca_file}"; do
  if [ ! -s "${file}" ]; then
    echo "Technitium ACME deploy hook: required certificate file missing: ${file}" >&2
    exit 1
  fi
done

mkdir -p "${target_dir}"

openssl pkcs12 -export \
  -out "${tmp_pfx}" \
  -inkey "${key_file}" \
  -in "${cert_file}" \
  -certfile "${ca_file}" \
  -passout "pass:${TECHNITIUM_PFX_PASSWORD}"

chmod 0600 "${tmp_pfx}"
mv -f "${tmp_pfx}" "${TECHNITIUM_PFX_TARGET}"

echo "Technitium ACME deploy hook: updated ${TECHNITIUM_PFX_TARGET}"
