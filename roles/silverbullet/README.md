# SilverBullet

Browserbasierter Markdown-Notizeditor mit Kopierbutton für Codeblöcke. Die Daten liegen im Saltbox-Appdata-Verzeichnis. Diese Rolle verwendet das offizielle Image und bindet dessen Datenverzeichnis nach `/data` ein.

## Installation

```bash
sb install saltbox-mod
sb install mod-silverbullet
```

Danach `https://silverbullet.<saltbox-domain>` öffnen und beim ersten Start über das SilverBullet-Dashboard den Zugang einrichten. Bei aktuellen Versionen läuft eine Neuinstallation im Multi-Space-Modus; `SB_USER` gehört nur zum älteren Single-Space-Modus.

## Konfiguration

Subdomain und Domain können im Saltbox Inventory überschrieben werden:

```yaml
silverbullet_role_web_subdomain: notes
silverbullet_role_web_domain: example.com
```

Standardmäßig greift die Saltbox-Traefik-SSO-Middleware. Für einen bewusst anderweitig abgesicherten Zugang kann sie im Inventory geändert werden:

```yaml
silverbullet_role_traefik_sso_middleware: ""
```

Für zusätzliche Umgebungsvariablen und Mounts stehen `silverbullet_role_docker_envs_custom` und `silverbullet_role_docker_volumes_custom` bereit. Die Daten liegen standardmäßig unter `{{ server_appdata_path }}/silverbullet/data`; sichern Sie dieses Verzeichnis regelmäßig. Wenn vorhandene Markdown-Dateien eingebunden werden sollen, den vollständigen Datenpfad per Inventory überschreiben, bevor die Rolle installiert wird:

```yaml
silverbullet_role_paths_data_location: /pfad/zu/meinen/notizen
```

Der Container übernimmt standardmäßig UID/GID des eingebundenen Datenverzeichnisses. Es werden keine Host-Ports veröffentlicht; Traefik leitet intern auf Port 3000.

Weitere Details: [SilverBullet Docker](https://v2.silverbullet.md/Install/Docker) und [Konfiguration](https://silverbullet.md/Install/Configuration).
