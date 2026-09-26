# saltbox_mod

Custom Saltbox-compatible Ansible roles for my Saltbox host.

This repository is based on [`saltyorg/saltbox_mod`](https://github.com/saltyorg/saltbox_mod) and is intended to hold only locally maintained roles. Host-specific values and secrets belong in the Saltbox Inventory or Saltbox facts, not in this repository.

## Connect Saltbox to this fork

Add the following to the Saltbox Inventory:

```yaml
saltbox_mod_repo: "https://github.com/s3tupw1zard/saltbox_mod.git"
saltbox_mod_branch: "main"
saltbox_mod_force_overwrite: true
```

Then run:

```bash
sb install saltbox-mod
```

For this repository, GitHub is intended to be the source of truth. Keeping `saltbox_mod_force_overwrite: true` means rerunning `sb install saltbox-mod` refreshes `/opt/saltbox_mod` from this fork. Do not keep uncommitted local changes in `/opt/saltbox_mod`, because they may be overwritten by the sync.

## kkRepo

The kkRepo role is registered and can be installed with:

```bash
sb install saltbox-mod
sb install mod-kkrepo
```

It uses `ghcr.io/klboke/kkrepo:latest`, deploys a private MySQL 8.0 companion container and persists application data under the normal Saltbox appdata path.

On a new installation, database and application secrets are generated once and persisted with Saltbox facts. Existing secrets can instead be imported through the Inventory on the first run. See [`roles/kkrepo/README.md`](roles/kkrepo/README.md) before migrating an existing installation.

## Infisical

The Infisical role is registered and can be installed with:

```bash
sb install saltbox-mod
sb install mod-infisical
```

It deploys `infisical/infisical:latest` together with private PostgreSQL 14 and Redis containers. The backend is exposed through the normal Saltbox Traefik/DNS integration, while PostgreSQL and Redis remain on a private Docker network.

Application secrets and integration credentials remain in the external Infisical `.env` file under the normal appdata path. The role never writes secret values to this repository and does not overwrite an existing `.env`. See [`roles/infisical/README.md`](roles/infisical/README.md) for migration and first-install instructions.

## Technitium DNS Server

The Technitium role is registered and can be installed with:

```bash
sb install saltbox-mod
sb install mod-technitium
```

It uses the official `docker.io/technitium/dns-server:latest` image. The web console is exposed through Saltbox Traefik at `technitium.<domain>`, while the DNS service is published on TCP/UDP port 53 and gets a separate unproxied `dns.<domain>` record.

On a fresh installation, the role generates a random Technitium admin password and persists it with Saltbox facts instead of leaving the upstream default credentials active. See [`roles/technitium/README.md`](roles/technitium/README.md) for the generated password location, DNS bind-address overrides, port-53 considerations and encrypted-DNS options.

## Installing a custom role

Every real role must be registered in `saltbox_mod.yml`:

```yaml
- { role: appname, tags: ['appname'] }
```

Deploy it with:

```bash
sb install mod-appname
```

When the role was changed on GitHub, sync the fork first and then deploy the role:

```bash
sb install saltbox-mod
sb install mod-appname
```

## Creating a role

`roles/_template` is a non-deployed template that follows the current Saltbox role conventions.

Copy it and replace the placeholder name:

```bash
cd /opt/saltbox_mod
APP=myapp
cp -a roles/_template "roles/$APP"
find "roles/$APP" -type f -exec sed -i "s/appname/$APP/g" {} +
```

Then adjust at least:

- Docker image repository and tag
- web port
- environment variables
- volume mounts
- host-published ports, if required
- Traefik/API settings if required
- any additional directories, networks, devices, capabilities or commands

Finally register the role in `saltbox_mod.yml`.

## Inventory overrides

Use Saltbox Inventory overrides for machine-specific settings. Prefer `_custom` variables where a role exposes a `*_default` / `*_custom` pair.

Example:

```yaml
myapp_role_docker_envs_custom:
  SOME_SETTING: "value"
```

Do not commit passwords, API keys, tokens or other secrets to this repository.

## Repository layout

```text
saltbox_mod.yml          # playbook and role registration
settings.yml             # legacy compatibility; Inventory is preferred
roles/
  _template/             # copy-only role template, not deployed
  kkrepo/                # kkRepo + MySQL role
  infisical/             # Infisical + PostgreSQL + Redis role
  technitium/            # Technitium DNS Server role
  <app>/                 # other custom roles
examples/
  kkrepo/                # standalone Compose reference
```

## Updating containers

Running a role again causes Saltbox to pull the configured image when `*_role_docker_image_pull: true` and recreate the container as needed:

```bash
sb install mod-appname
```

Automatic image monitoring/updating is separate from the role itself. Saltbox provides Diun for update notifications, while Dockwatch can manage actual updates when explicitly configured with the required Docker socket permissions.
