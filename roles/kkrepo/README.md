# kkRepo Saltbox role

Installs kkRepo with an internal MySQL 8.0 container and exposes kkRepo through the normal Saltbox Traefik/DNS integration.

The kkRepo image is intentionally configured as:

```text
ghcr.io/klboke/kkrepo:latest
```

## New installation

No secret values need to be added to the repository or Inventory.

```bash
sb install saltbox-mod
sb install mod-kkrepo
```

On the first run the role generates four independent random 64-character secrets and persists them through Saltbox's `saltbox_facts` mechanism:

- MySQL root password
- kkRepo MySQL user password
- kkRepo credential encryption secret
- kkRepo API-key payload secret

The persisted values are stored in the Saltbox facts area (`{{ server_appdata_path }}/saltbox/kkrepo.ini`; normally `/opt/saltbox/kkrepo.ini`) with mode `0600`.

Subsequent runs load the existing values. New random candidates are never allowed to replace existing facts.

## Import an existing installation

Before the first `mod-kkrepo` run on the new role, add the existing values to the Saltbox Inventory:

```yaml
kkrepo_role_mysql_root_password: "EXISTING_ROOT_PASSWORD"
kkrepo_role_mysql_password: "EXISTING_KKREPO_DB_PASSWORD"
kkrepo_role_credential_secret: "EXISTING_KKREPO_CREDENTIAL_SECRET"
kkrepo_role_api_key_payload_secret: "EXISTING_KKREPO_API_KEY_PAYLOAD_SECRET"
```

Then run:

```bash
sb install saltbox-mod
sb install mod-kkrepo
```

Once the values have been persisted to Saltbox facts, the four Inventory entries may be removed. The persisted facts remain authoritative on later runs.

If an initialized kkRepo MySQL directory already exists but required persisted facts are missing, the role intentionally aborts instead of generating replacement secrets. Import the original values first.

## Backup requirement

Back up both the kkRepo application data and the Saltbox facts file. The important paths are normally:

```text
/opt/kkrepo/data
/opt/kkrepo/mysql
/opt/saltbox/kkrepo.ini
```

The database/blob data and the secrets belong together. Restoring the data without the matching secrets can make the existing installation unusable.

## Defaults

The service is exposed at the standard Saltbox hostname derived from:

```yaml
kkrepo_role_web_subdomain: kkrepo
kkrepo_role_web_domain: "{{ user.domain }}"
```

External Saltbox SSO is disabled by default because Maven, Gradle and other repository clients need to authenticate directly against kkRepo.
