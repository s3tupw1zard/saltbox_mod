# Infisical Saltbox role

Installs the Infisical backend together with private PostgreSQL 14 and Redis companion containers and exposes only the backend through the normal Saltbox Traefik/DNS integration.

The role is intentionally host-neutral. The public hostname is derived from the normal Saltbox settings:

```yaml
infisical_role_web_subdomain: infisical
infisical_role_web_domain: "{{ user.domain }}"
```

No concrete personal domain is stored in this repository.

## Existing installation

The role is designed to take over an existing Compose installation under the normal Saltbox appdata path, typically `/opt/infisical`.

It reuses these files/directories unchanged:

```text
/opt/infisical/.env
/opt/infisical/pg_data
/opt/infisical/redis_data
```

The populated `.env` remains external to Git. The role never overwrites it.

For a migration from Compose:

```bash
cd /opt/infisical
docker compose down
sb install saltbox-mod
sb install mod-infisical
```

Do not use `docker compose down -v`; the PostgreSQL and Redis data must remain intact.

The private Docker network provides the aliases `db` and `redis`, so the standard Infisical values such as these continue to work:

```text
DB_CONNECTION_URI=postgres://...@db:5432/...
REDIS_URL=redis://redis:6379
```

`SITE_URL` and `PORT` are set by the Saltbox role at container creation time from the configured Saltbox web URL and port. They can still be overridden with `infisical_role_docker_envs_custom` when required.

## New installation

Run the role once to create the application directories and `.env.example`:

```bash
sb install saltbox-mod
sb install mod-infisical
```

If `.env` does not yet exist, the role intentionally stops after creating:

```text
/opt/infisical/.env.example
```

Create the real environment file and populate the required Infisical values:

```bash
cp /opt/infisical/.env.example /opt/infisical/.env
chmod 600 /opt/infisical/.env
```

Then run:

```bash
sb install mod-infisical
```

The environment template contains no secret values.

## Containers

The defaults follow Infisical's production Compose layout:

```text
infisical-backend      infisical/infisical:latest
infisical-db           postgres:14-alpine
infisical-dev-redis    redis:latest
```

PostgreSQL and Redis are attached only to the private `infisical` network. The backend is attached to both the private network and the normal Saltbox network so Traefik can reach it.

No host port is published for the backend, PostgreSQL or Redis.

## Environment file

All application secrets, OAuth credentials, SMTP values and optional integration credentials stay in:

```text
/opt/infisical/.env
```

The role passes that file to the containers but does not manage its contents. Back it up together with the PostgreSQL data.

## Overrides

Examples:

```yaml
infisical_role_web_subdomain: secrets
infisical_role_docker_image_tag: "<pinned-version>"
infisical_role_docker_envs_custom:
  SITE_URL: "https://secrets.example.org"
```

For production, pinning `infisical_role_docker_image_tag` to a tested Infisical release is preferable to tracking `latest` permanently.
