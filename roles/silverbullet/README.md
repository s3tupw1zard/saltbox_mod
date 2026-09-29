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

Der erste Aufruf läuft standardmäßig durch Saltbox-SSO, damit der noch unkonfigurierte Setup-Assistent nicht öffentlich erreichbar ist. Melde dich zuerst an Saltbox-SSO an. `/.setup/` ist die von SilverBullet 2.11 verwendete interne URL für den Einrichtungsassistenten; beim Aufruf der Basis-URL sollte sie automatisch erscheinen. Die Anwendung wird **nicht** auf einen anderen Setup-Pfad umgestellt.

Bei einem HTTP 401 zunächst die Antwort ohne Traefik testen und die tatsächlich aktiven Router-Labels prüfen:

```bash
docker exec traefik wget -S -O /dev/null http://silverbullet:3000/.setup/ 2>&1 | head -30
docker inspect silverbullet --format '{{json .Config.Labels}}'
ls -ld /opt/silverbullet/data
```

Ist die interne Setup-Seite erreichbar, aber die öffentliche URL antwortet 401, kommt die Sperre von einer vorgeschalteten Auth-Middleware oder einer SilverBullet-Zugangsregel; Dateirechte beheben keinen 401. Die Rolle setzt den Datenordner für den Saltbox-Benutzer schreibbar. Falls du die Saltbox-SSO-Middleware bewusst umgehen willst, richte vorher eine andere Zugangsbeschränkung ein und setze danach im Inventory `silverbullet_role_traefik_sso_middleware: ""` (anschließend `sb install mod-silverbullet`).

Für zusätzliche Umgebungsvariablen und Mounts stehen `silverbullet_role_docker_envs_custom` und `silverbullet_role_docker_volumes_custom` bereit. Die Daten liegen standardmäßig unter `{{ server_appdata_path }}/silverbullet/data`; sichern Sie dieses Verzeichnis regelmäßig. Wenn vorhandene Markdown-Dateien eingebunden werden sollen, den vollständigen Datenpfad per Inventory überschreiben, bevor die Rolle installiert wird:

```yaml
silverbullet_role_paths_data_location: /pfad/zu/meinen/notizen
```

Die Rolle setzt den Datenordner auf den Saltbox-Benutzer mit Schreibrechten. Der Container übernimmt automatisch UID/GID dieses Verzeichnisses. Bestehende Notizdateien werden dabei nicht rekursiv umgeschrieben. Es werden keine Host-Ports veröffentlicht; Traefik leitet intern auf Port 3000.

Weitere Details: [SilverBullet Docker](https://v2.silverbullet.md/Install/Docker) und [Konfiguration](https://silverbullet.md/Install/Configuration).
