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

SilverBullet übernimmt standardmäßig die Anmeldung selbst; eine zusätzliche Saltbox-SSO-Middleware ist für diese Rolle deaktiviert. `/.setup/` ist der von SilverBullet 2.11 verwendete Einrichtungsweg. Beim Aufruf der Basis-URL sollte die Einrichtung angezeigt werden. Falls weiterhin 401 erscheint, die tatsächlich gesetzten Traefik-Middleware-Labels und die Antwort über den internen Container-Port getrennt prüfen.

Falls du zusätzlich Saltbox-SSO möchtest, kannst du es bewusst im Inventory aktivieren:

```yaml
silverbullet_role_traefik_sso_middleware: "{{ traefik_default_sso_middleware }}"
```

Für zusätzliche Umgebungsvariablen und Mounts stehen `silverbullet_role_docker_envs_custom` und `silverbullet_role_docker_volumes_custom` bereit. Die Daten liegen standardmäßig unter `{{ server_appdata_path }}/silverbullet/data`; sichern Sie dieses Verzeichnis regelmäßig. Wenn vorhandene Markdown-Dateien eingebunden werden sollen, den vollständigen Datenpfad per Inventory überschreiben, bevor die Rolle installiert wird:

```yaml
silverbullet_role_paths_data_location: /pfad/zu/meinen/notizen
```

Die Rolle setzt den Datenordner auf den Saltbox-Benutzer mit Schreibrechten. Der Container übernimmt automatisch UID/GID dieses Verzeichnisses. Bestehende Notizdateien werden dabei nicht rekursiv umgeschrieben. Es werden keine Host-Ports veröffentlicht; Traefik leitet intern auf Port 3000.

Weitere Details: [SilverBullet Docker](https://v2.silverbullet.md/Install/Docker) und [Konfiguration](https://silverbullet.md/Install/Configuration).
