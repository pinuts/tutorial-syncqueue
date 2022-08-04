# ACHTUNG!
**Diese README-Datei sollte für dieses Projekt angepasst werden. Sie wird nicht automatisch überschrieben!**

Mehr Beispiele und Dokumentation siehe `Kickstarter.md`.

# Mit dem Kickstarter-UM arbeiten

UM installieren und Konfigurationsdateien gemäß `build.gradle` kopieren bzw. verlinken:
```bash
gradle setup
```

UM starten:
```bash
gradle run
```

"Deployable" = ZIP-File für Umgebung `${ENVIRONMENT}` bauen:
```bash
gradle dist -Penv=${ENVIRONMENT}
```

Docker-Image für Umgebung `${ENVIRONMENT}` bauen:
```bash
gradle dockerimage -Penv=${ENVIRONMENT}
```

UM inkl. Datenbank löschen:
```bash
gradle destroy
```

Datenbank-UI im Browser öffnen:
```bash
gradle h2console
```

Updaten der Kickstarter-Skripte (`.umstarter.gradle`):
```bash
gradle update
```
