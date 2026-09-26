# Technitium DNS Server Saltbox role

Installs the official Technitium DNS Server Docker image, exposes its web console through the normal Saltbox Traefik integration, and uses a dedicated `acme.sh` companion for the certificate used by DNS-over-TLS and DNS-over-QUIC.

The main image is:

```text
docker.io/technitium/dns-server:latest
```

The ACME companion uses:

```text
neilpang/acme.sh:latest
```

## Default hostnames

The role uses the domain already configured in Saltbox (`user.domain`) and keeps the web and DNS service names separate by default:

```yaml
technitium_role_web_subdomain: technitium
technitium_role_web_domain: "{{ user.domain }}"

technitium_role_service_dns_record: dns
technitium_role_service_dns_zone: "{{ user.domain }}"
```

This produces:

```text
https://technitium.<saltbox-domain>   Web console through Traefik
dns.<saltbox-domain>                  DNS / DoT / DoQ, direct and unproxied
```

Both parts are role-specific overrides. Nothing requires the web and DNS names to be different.

For example, to use the same hostname for everything:

```yaml
technitium_role_web_subdomain: technitium
technitium_role_service_dns_record: technitium
```

With the default Saltbox domain, both then resolve as `technitium.<saltbox-domain>`. In this shared-hostname mode the role creates only one DNS record and deliberately leaves it unproxied. Traefik can still serve the web console on HTTPS, while TCP/UDP DNS traffic reaches the host directly.

The DNS service record must not use the normal Cloudflare HTTP proxy because DNS on port 53 and DoT/DoQ on port 853 need to reach the Saltbox host directly.

## Install

```bash
sb install saltbox-mod
sb install mod-technitium
```

On a default installation the host publishes:

```text
53/udp    DNS
53/tcp    DNS
853/tcp   DNS-over-TLS
853/udp   DNS-over-QUIC
```

The Technitium web port `5380` is not published on the host. Traefik reaches it through the common Saltbox Docker network.

## Classic DNS port overrides

Classic DNS is enabled by default and keeps the standard host/container port mapping:

```yaml
technitium_role_dns_enabled: true
technitium_role_dns_host_port: "53"
technitium_role_dns_port: "53"
```

`technitium_role_dns_host_port` is the port published on the Saltbox host. `technitium_role_dns_port` is the DNS port inside the Technitium container and should normally remain `53`.

If another local service already owns host port 53, keep Technitium's internal DNS port unchanged and only move the host-side mapping, for example:

```yaml
technitium_role_dns_enabled: true
technitium_role_dns_host_port: "5300"
technitium_role_dns_port: "53"
```

That produces:

```text
5300/udp -> technitium:53/udp
5300/tcp -> technitium:53/tcp
```

To stop publishing classic DNS entirely while leaving DoT/DoQ available:

```yaml
technitium_role_dns_enabled: false
```

These variables affect only classic DNS. DNS-over-TLS and DNS-over-QUIC continue to use their own feature flags and port settings.

## Dedicated ACME companion

Traefik remains responsible only for the HTTPS certificate used by the web console. The DNS protocols get their own certificate lifecycle.

The `technitium-acme` companion:

1. requests a certificate for `technitium_role_service_dns_fqdn` using DNS-01;
2. keeps its ACME account and renewal state under `/opt/technitium/acme`;
3. exports the renewed certificate through acme.sh's supported `--install-cert` mechanism;
4. converts the certificate and private key to PKCS#12;
5. atomically replaces `/opt/technitium/tls/dns.pfx`;
6. remains running as acme.sh's renewal daemon.

The ACME container publishes no ports and does not receive the Docker socket.

Technitium mounts only the final TLS directory read-only and uses:

```text
/etc/dns/tls/dns.pfx
```

for its optional DNS protocols. Technitium monitors the certificate file and reloads certificate changes automatically, so renewal does not require restarting the DNS container.

### Cloudflare credentials

The default provider is Cloudflare:

```yaml
technitium_role_acme_dns_provider: dns_cf
```

When Saltbox already has Cloudflare configured, the role automatically reuses the credentials from the normal Saltbox account configuration. A scoped token is preferred when available; the legacy API key plus account email is also supported.

No Cloudflare token is committed to this repository. The generated runtime environment file is stored as root-only `0600` at:

```text
/opt/technitium/acme.env
```

If you want this role to use separate Cloudflare credentials, override them explicitly:

```yaml
technitium_role_acme_envs_custom:
  CF_Token: "YOUR_DEDICATED_TOKEN"
```

For another acme.sh DNS provider, select its provider name and supply the environment variables required by that provider:

```yaml
technitium_role_acme_dns_provider: "dns_PROVIDER"
technitium_role_acme_envs_custom:
  PROVIDER_VARIABLE: "value"
```

Use the acme.sh DNS API documentation for the exact provider name and environment-variable names.

### ACME settings

Useful overrides include:

```yaml
technitium_role_acme_enabled: true
technitium_role_acme_email: "{{ user.email }}"
technitium_role_acme_server: letsencrypt
technitium_role_acme_key_length: ec-256
```

The ACME email defaults to the email already configured for the Saltbox user.

## PKCS#12 password

Technitium needs a password for the generated `.pfx`. If this is left empty:

```yaml
technitium_role_acme_pfx_password: ""
```

the role generates a random 64-character value and persists it with `saltbox_facts`. The persisted value is stored with the other Technitium facts, normally in:

```text
/opt/saltbox/technitium.ini
```

It does not need to be committed to Inventory or Git.

## Initial Technitium administrator password

Technitium's built-in administrator account is `admin`. On a new installation the role generates a random administrator password instead of leaving the upstream default credentials active.

The generated password is also persisted through Saltbox facts in:

```text
/opt/saltbox/technitium.ini
```

To provide your own password before the first installation:

```yaml
technitium_role_admin_password: "YOUR_INITIAL_PASSWORD"
```

Technitium Docker initialization variables are only consumed while `/etc/dns/dns.config` does not yet exist.

### Existing Technitium installations

For a fresh installation, the role automatically logs in to Technitium after startup and configures the generated certificate, DNS-over-TLS and DNS-over-QUIC.

For an existing installation the role does not assume that a previously stored administrator password is still valid, since it may have been changed inside Technitium. To allow one automatic encrypted-DNS configuration pass, temporarily provide the current administrator password:

```yaml
technitium_role_admin_password: "CURRENT_ADMIN_PASSWORD"
```

Run:

```bash
sb install mod-technitium
```

After the encrypted DNS settings have been applied, the Inventory override can be removed again. Certificate renewals do not require the administrator password.

## DNS-over-TLS and DNS-over-QUIC

Both are enabled by default:

```yaml
technitium_role_dot_enabled: true
technitium_role_dot_port: "853"

technitium_role_doq_enabled: true
technitium_role_doq_port: "853"
```

Disabling either feature also removes its corresponding default host port mapping on the next role run.

Technitium terminates TLS/QUIC itself. Traefik is not placed in front of port 853.

## DNS-over-HTTPS

This role deliberately does not publish Technitium's native HTTPS listener on host port 443 because Saltbox Traefik already owns that port.

If DNS-over-HTTPS is added later, the clean Saltbox design is to let Traefik terminate HTTPS and reverse-proxy `/dns-query` to Technitium's internal DNS-over-HTTP listener, for example port `8053`. In that design Traefik uses its own web certificate and the dedicated ACME/PFX certificate remains for protocols that terminate TLS directly in Technitium, primarily DoT and DoQ.

## DNS bind address

By default DNS services bind on all host IPv4 interfaces:

```yaml
technitium_role_dns_bind_ip: "0.0.0.0"
```

To restrict them to a LAN, NetBird, Tailscale or another interface, override the value:

```yaml
technitium_role_dns_bind_ip: "100.64.0.10"
```

Make sure the configured classic DNS host port and, when enabled, TCP/UDP port 853 are free on the selected address.

The role intentionally does not disable `systemd-resolved` or any other resolver automatically.

## Paths and backups

Persistent paths are normally:

```text
/opt/technitium/config       Technitium configuration
/opt/technitium/logs         Technitium logs
/opt/technitium/acme         ACME account, certificate and renewal state
/opt/technitium/tls/dns.pfx  PKCS#12 certificate consumed by Technitium
/opt/saltbox/technitium.ini  Persisted role secrets
```

Back up at least the Technitium configuration and Saltbox facts. Backing up ACME state avoids creating a new ACME account after a full restore, although a new certificate can be issued again when the DNS provider credentials remain available.

## Useful hostname overrides

Separate hostnames on another domain:

```yaml
technitium_role_web_subdomain: dns-admin
technitium_role_web_domain: example.net
technitium_role_service_dns_record: resolver
technitium_role_service_dns_zone: example.net
```

Shared hostname:

```yaml
technitium_role_web_subdomain: technitium
technitium_role_service_dns_record: technitium
```

The derived values are:

```text
technitium_role_web_fqdn
technitium_role_service_dns_fqdn
```

Normally they should not be overridden directly; override the subdomain/record and domain/zone variables instead.

## Upstream documentation

- Technitium DNS Server Docker configuration: <https://github.com/TechnitiumSoftware/DnsServer/blob/master/docker-compose.yml>
- Technitium Docker environment variables: <https://github.com/TechnitiumSoftware/DnsServer/blob/master/DockerEnvironmentVariables.md>
- Technitium HTTP API: <https://github.com/TechnitiumSoftware/DnsServer/blob/master/APIDOCS.md>
- acme.sh: <https://github.com/acmesh-official/acme.sh>
- acme.sh DNS providers: <https://github.com/acmesh-official/acme.sh/wiki/dnsapi>
