#!/usr/bin/env sh
set -eu

: "${TECHNITIUM_ACME_DOMAIN:?TECHNITIUM_ACME_DOMAIN is required}"
: "${TECHNITIUM_ACME_SERVER:?TECHNITIUM_ACME_SERVER is required}"
: "${TECHNITIUM_ACME_DNS_PROVIDER:?TECHNITIUM_ACME_DNS_PROVIDER is required}"
: "${TECHNITIUM_ACME_KEY_LENGTH:?TECHNITIUM_ACME_KEY_LENGTH is required}"
: "${TECHNITIUM_PFX_PASSWORD:?TECHNITIUM_PFX_PASSWORD is required}"
: "${TECHNITIUM_PFX_TARGET:?TECHNITIUM_PFX_TARGET is required}"

case "${TECHNITIUM_ACME_KEY_LENGTH}" in
  ec-*)
    cert_dir="/acme.sh/${TECHNITIUM_ACME_DOMAIN}_ecc"
    ecc_arg="--ecc"
    ;;
  *)
    cert_dir="/acme.sh/${TECHNITIUM_ACME_DOMAIN}"
    ecc_arg=""
    ;;
esac

acme.sh --set-default-ca --server "${TECHNITIUM_ACME_SERVER}"

if [ -n "${TECHNITIUM_ACME_EMAIL:-}" ]; then
  acme.sh --register-account \
    --server "${TECHNITIUM_ACME_SERVER}" \
    -m "${TECHNITIUM_ACME_EMAIL}"
fi

if [ ! -s "${cert_dir}/${TECHNITIUM_ACME_DOMAIN}.conf" ]; then
  acme.sh --issue \
    --server "${TECHNITIUM_ACME_SERVER}" \
    --dns "${TECHNITIUM_ACME_DNS_PROVIDER}" \
    -d "${TECHNITIUM_ACME_DOMAIN}" \
    --keylength "${TECHNITIUM_ACME_KEY_LENGTH}"
fi

if [ -n "${ecc_arg}" ]; then
  acme.sh --to-pkcs12 \
    -d "${TECHNITIUM_ACME_DOMAIN}" \
    --ecc \
    --password "${TECHNITIUM_PFX_PASSWORD}"

  acme.sh --install-cert \
    -d "${TECHNITIUM_ACME_DOMAIN}" \
    --ecc \
    --reloadcmd "/opt/technitium-acme/deploy-pfx.sh"
else
  acme.sh --to-pkcs12 \
    -d "${TECHNITIUM_ACME_DOMAIN}" \
    --password "${TECHNITIUM_PFX_PASSWORD}"

  acme.sh --install-cert \
    -d "${TECHNITIUM_ACME_DOMAIN}" \
    --reloadcmd "/opt/technitium-acme/deploy-pfx.sh"
fi

exec /entry.sh daemon
