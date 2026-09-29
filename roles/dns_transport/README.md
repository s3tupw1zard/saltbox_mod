# DNS over TLS and QUIC through Saltbox Traefik

This optional role adds generic DNS transport routing to Saltbox's existing Traefik file provider. The DNS backend can be Technitium or another container reachable on the Saltbox common Docker network.

- DoT: Traefik terminates TLS on TCP/853, then forwards plain DNS over TCP to the backend (default internal port 53). Traefik obtains the certificate through the configured Saltbox certificate resolver.
- DoQ: Traefik forwards UDP/853 to the backend's DoQ listener (default internal port 853). The backend terminates QUIC and must have a trusted certificate matching the DNS hostname. Traefik does not terminate DoQ.

## Saltbox Inventory (static Traefik configuration)

Append these items to any existing custom lists; do not replace items you already use:

```yaml
traefik_role_docker_commands_custom:
  - "--entrypoints.dot.address=:853/tcp"
  - "--entrypoints.doq.address=:853/udp"
traefik_role_docker_ports_custom:
  - "853:853/tcp"
  - "853:853/udp"

dns_transport_role_backend_host: "technitium" # or another Docker DNS backend
dns_transport_role_domain: "dns.s3tupw1zard.dev"
```

The two `traefik_role_*` lists are consumed by Saltbox's original Traefik role; this mod does not replace its defaults. Traefik's new entrypoints need a restart. If only one protocol is wanted, remove its unused entrypoint/port and set `dns_transport_role_dot_enabled: false` or `dns_transport_role_doq_enabled: false`.

Point the DNS hostname directly to the host (Cloudflare DNS-only, no HTTP proxy) and make TCP/853 and UDP/853 reachable through your firewall. For DoT the configured Saltbox ACME resolver must issue a certificate for that exact hostname. For DoQ the backend must independently hold a valid certificate.

## Install or update

Ensure the current DNS server releases the public TCP/853 and UDP/853 bindings **before** redeploying Traefik on those ports. Do not disable its internal listeners. With the Technitium role in this repository, set:

```yaml
technitium_role_dot_publish_port: false
technitium_role_doq_publish_port: false
```

Then:

```bash
sb install saltbox-mod
sb install mod-technitium  # only when Technitium owns public port 853
sb install traefik
sb install mod-dns_transport
```

For another backend, configure its port publication and use its Docker hostname in `dns_transport_role_backend_host`; `mod-technitium` is not required. The backend must be on a network shared with Traefik.

This role writes `{{ server_appdata_path }}/traefik/dns-transport.yml` into Saltbox's already mounted file-provider directory. It does not overwrite Saltbox's Traefik settings. Its `dns-dot@file` TLS option accepts ALPN `dot` without changing the TLS options used by HTTPS services.

## Backend overrides

```yaml
dns_transport_role_dot_backend_port: "53"
dns_transport_role_doq_backend_port: "853"
dns_transport_role_certresolver: "{{ traefik_default_certresolver }}"
```

UDP routing cannot select a backend by hostname/SNI on the same entrypoint. Only one DoQ backend should own this UDP/853 entrypoint. Traefik forwards UDP packets rather than inspecting QUIC; the DNS backend may see the proxy as its peer rather than the original client. Test with `kdig +tls @dns.s3tupw1zard.dev example.org` for DoT and a DoQ-capable DNS client for DoQ.
