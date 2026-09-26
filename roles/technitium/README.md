# Technitium DNS Server Saltbox role

Installs the official Technitium DNS Server Docker image and exposes the web console through the normal Saltbox Traefik/DNS integration.

The image is configured as:

```text
docker.io/technitium/dns-server:latest
```

The role keeps the web console and DNS service hostnames separate by default:

```yaml
technitium_role_web_subdomain: technitium
technitium_role_service_dns_record: dns
```

This results in:

```text
https://technitium.<domain>   # Web console through Traefik
dns.<domain>:53               # DNS service, direct/unproxied
```

The DNS service record is intentionally created without Cloudflare proxying. Standard DNS traffic on TCP/UDP port 53 cannot be carried through the normal Cloudflare HTTP proxy.

## Install

```bash
sb install saltbox-mod
sb install mod-technitium
```

The default container publishes DNS on TCP and UDP port 53 and keeps the web console port 5380 internal to the common Saltbox Docker network for Traefik.

## Initial admin password

Technitium's built-in administrator account is `admin`. On a fresh installation this role does not leave the upstream default password in place.

If `technitium_role_admin_password` is empty, the role generates a random 64-character password and persists it using Saltbox facts. The facts file is normally:

```text
/opt/saltbox/technitium.ini
```

Inspect that file after the first install to obtain the generated password.

To provide your own initial password, set this in the Saltbox Inventory before the first install:

```yaml
technitium_role_admin_password: "YOUR_INITIAL_PASSWORD"
```

The password is persisted to Saltbox facts during initialization, so the Inventory value can be removed afterwards.

Technitium Docker initialization environment variables are only read when `/etc/dns/dns.config` does not yet exist. Changing `technitium_role_admin_password`, `technitium_role_server_domain` or another initialization environment variable later does not reconfigure an existing Technitium installation; make later changes through the Technitium web console/API.

If an existing Technitium config is adopted by this role, the role leaves its existing administrator credentials untouched.

## Paths and backups

Persistent data is stored under the normal Saltbox appdata path:

```text
/opt/technitium/config
/opt/technitium/logs
```

The important backup paths are:

```text
/opt/technitium/config
/opt/saltbox/technitium.ini
```

The logs directory is optional for backup purposes.

## DNS bind address

By default, port 53 is published on all host IPv4 interfaces:

```yaml
technitium_role_dns_bind_ip: "0.0.0.0"
```

If this resolver should only be reachable through a LAN, NetBird, Tailscale or another private interface, override the value with that interface's host address before installing:

```yaml
technitium_role_dns_bind_ip: "100.64.0.10"
```

Technitium defaults recursive resolution to private networks only, but binding the service only where it is actually needed is still preferable.

Make sure TCP and UDP port 53 are free on the selected host address. If another resolver is already listening there, inspect it before installing:

```bash
sudo ss -lntup | grep ':53 '
```

The role intentionally does not stop or disable `systemd-resolved` or any other host resolver automatically.

## DNS-over-TLS and DNS-over-QUIC

The upstream image also supports DNS-over-TLS and DNS-over-QUIC on port 853. They are not published by default.

They can be exposed with:

```yaml
technitium_role_docker_ports_custom:
  - "{{ technitium_role_dns_bind_ip }}:853:853/tcp"
  - "{{ technitium_role_dns_bind_ip }}:853:853/udp"
```

Configure TLS certificates and enable the corresponding protocols inside Technitium afterwards.

DNS-over-HTTPS normally uses port 443, which is already owned by Traefik on a Saltbox host. Do not publish the Technitium container directly on host port 443 without redesigning that routing. Technitium's port 8053 or a dedicated Traefik route can be used for a later DoH setup.

## DHCP

The role is intentionally configured for DNS service using Docker bridge networking. Technitium's upstream Docker deployment recommends host networking for DHCP deployments. DHCP is therefore not enabled by this role.

## Useful overrides

```yaml
# Web UI hostname
technitium_role_web_subdomain: technitium

# Direct DNS hostname
technitium_role_service_dns_record: dns

# Bind DNS only to a specific host interface
technitium_role_dns_bind_ip: "100.64.0.10"

# Add additional Docker environment variables supported by Technitium
technitium_role_docker_envs_custom:
  DNS_SERVER_PREFER_IPV6: "false"

# Add additional published ports
technitium_role_docker_ports_custom: []
```

Upstream Docker configuration and environment-variable documentation:

- https://github.com/TechnitiumSoftware/DnsServer/blob/master/docker-compose.yml
- https://github.com/TechnitiumSoftware/DnsServer/blob/master/DockerEnvironmentVariables.md
