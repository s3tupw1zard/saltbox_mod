# saltbox_mod

Custom Saltbox-compatible Ansible roles for my Saltbox host.

This repository is based on [`saltyorg/saltbox_mod`](https://github.com/saltyorg/saltbox_mod) and is intended to hold only locally maintained roles. Host-specific values and secrets belong in the Saltbox Inventory, not in this repository.

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

After the first successful switch to this fork, set:

```yaml
saltbox_mod_force_overwrite: false
```

The repository is installed to `/opt/saltbox_mod` by Saltbox.

## Installing a custom role

Every real role must be registered in `saltbox_mod.yml`:

```yaml
- { role: appname, tags: ['appname'] }
```

Deploy it with:

```bash
sb install mod-appname
```

For example, a future `kkrepo` role will be installed with:

```bash
sb install mod-kkrepo
```

## Creating a role

`roles/_template` is a non-deployed template that follows the current Saltbox role conventions.

Copy it and replace the placeholder name:

```bash
cd /opt/saltbox_mod
APP=kkrepo
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
  <app>/                 # actual custom roles
```

## Updating containers

Running a role again causes Saltbox to pull the configured image when `*_role_docker_image_pull: true` and recreate the container as needed:

```bash
sb install mod-appname
```

Automatic image monitoring/updating is separate from the role itself. Saltbox provides Diun for update notifications, while tools such as Dockwatch can manage updates when explicitly configured with the required Docker socket permissions.
