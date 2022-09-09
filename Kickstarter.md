# UM-Kickstarter



## Mit dem Kickstarter-UM arbeiten

UM installieren und Konfigurationsdateien gemäß `build.gradle` kopieren bzw. verlinken:
```bash
gradle setup
```

Hier kommt ggf. eine Fehlermeldung, die besagt, dass der Installer die Lizenz nicht finden konnte.
Sie muss manuell unter `env/devel/cmsbs-conf/cmsbs.license` abgelegt werden. 

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

## UM-Plugins aus Mavenrepo einbinden

UM-Plugins aus unserem [Mavenrepo](https://admin.cloudrepo.io/repository/um/de/pinuts/cmsbs)
können in `build.gradle` in den
_dependencies_ angefordert werden. Sie werden dann automatisch nach `UM/cmsbs-conf/cse/plugins/`
ausgepackt.
```groovy
dependencies {
    runtime('de.pinuts.cmsbs:UM:7.34.1')
    runtime('de.pinuts.cmsbs:CseConsole:7.32.0')
}
```

## Eigenes UM-Plugin erstellen

Eigene Plugins gehören nach `cmsbs-conf/cse/plugins/`. Sie werden per Symlink
im _setup.doLast_-Block in den lokalen UM eingebunden, z.B.:
```groovy
setup.doLast {
    ln('cmsbs-conf/cse/plugins/de.pinuts.myumaddon', pinuts.um.pluginsDir)
}
```
Beispiele und API-Dokumentation gibt es hier: [UM-API-Doc](https://www.universal-messenger.de/knowledge-base/intern/doc-api/api-cse/)

## REST-Proxy in Entwicklungsumgebung nutzen

Soll der REST-Proxy auch im embedded Tomcat lokal unter `/p` erreichbar sein, geht das wie folgt:
```groovy
setup.doLast {
    cp('rest-proxy/cmsbs-restproxy.properties', new File(pinuts.um.serverHome, 'cmsbs-restproxy.properties'))
    cp('UM/web-integration/cmsbs-restproxy.war', new File(pinuts.um.webappsDir, 'p.war'))
}
```

## "Deployables" bauen

Umgebungsspezifische Konfiguration kommt nach `env/${ENVIRONMENT}/cmsbs-conf/` und die üblichen
Unterverzeichnisse. `${ENVIRONMENT}` kann z.B. "devel" (Default), "stage", "prod" oder
sonst irgendein möglichst sprechender Name für eine bestimmte Zielumgebung sein.

Für die Umgebung "prod" kann dann wie folgt ein ZIP-File gebaut werden:

```bash
gradle dist -Penv=prod
```

Das Ergebnis landet unter `build/${PROJECT_NAME}-prod.zip`.

In diesem ZIP-File landet automatisch etwa Folgendes:
* `cmsbs-conf/**`
* `env/${ENVIRONMENT}/**`
* `UM/cmsbs-conf/cse/plugins/**`

Weitere Dateien kann man in einem _dist.doLast_-Block ins ZIP-File aufnehmen. Dazu
eignet sich [_ant.zip_](https://ant.apache.org/manual/Tasks/zip.html) besonders gut, z.B.
```groovy
dist.doLast {
    // REST-Proxy: Add log4j2.properties to cmsbs-restproxy.war
    ant.zip(destfile: 'UM/web-integration/cmsbs-restproxy.war', update: true) {
        zipfileset(dir: 'rest-proxy', includes: 'log4j2.properties', fullpath: 'WEB-INF/classes/log4j2.properties')
    }
    // REST-Proxy: Add cmsbs-restproxy.war as p.war
    ant.zip(destfile: pinuts.distFilename, update: true) {
        zipfileset(dir: 'UM/web-integration', includes: 'cmsbs-restproxy.war', fullpath: 'cmsbs-work/webapps/p.war')
    }
    // REST-Proxy: Add cmsbs-restproxy.properties
    ant.zip(destfile: pinuts.distFilename, update: true) {
        zipfileset(dir: 'rest-proxy', includes: 'cmsbs-restproxy.properties')
    }

    // JAR-Files aus `cmsbs/WEB-INF/lib/`:
    ant.zip(destfile: pinuts.distFilename, update: true) {
        zipfileset(dir: '.', includes: 'cmsbs/**/*.jar')
    }

    // Weitere JAR-Files aus anderem Verzeichnis `my-libs/`:
    ant.zip(destfile: pinuts.distFilename, update: true) {
        zipfileset(dir: 'my-libs', includes: '**/*.jar', prefix: 'cmsbs/WEB-INF/lib')
    }
}
```

### Versionsnummer des Deployables
Die Versionsnummer des Deployables kann entweder als Konstante festgelegt
```groovy
pinuts.version = '3.1.4'
```
oder aus *dem* Plugindesriptor ausgelesen werden:
```groovy
pinuts.version = getVersionFromPluginDescriptor('the_plugin/plugin.desc.json')
```
`the_plugin` sollte ein Symlink auf *den* Plugin-Ordner sein, der auch mit ins Git gehört:
```bash
ln -s cmsbs-conf/cse/plugins/de.pinuts.myumaddon the_plugin
```

## Plugin in eigenem Maven-Repo veröffentlichen

Das per `gradle dist` gebaute UM-Plugin kann in einem eigenen -- ggf. S3-basierten -- Maven-Repo veröffentlich werden.
(S3-Unterstützung ist in gradle erst ab Version 5 enhalten.)
Dazu wird in `build.gradle` folgender Block *hinter* dem der Zuweisung `pinuts.version = ...` eingefügt:
```groovy
...
// pinuts.projectName = 'MyProject'
// pinuts.groupId = 'de.customer'
// pinuts.version = getVersionFromPluginDescriptor('the_plugin/plugin.desc.json')

publishing {
    publications {
        cmsbsPlugin(MavenPublication) {
            groupId = pinuts.groupId
            artifactId = pinuts.projectName
            version = "${pinuts.env}-SNAPSHOT"
            artifact getCmsbsPluginDistFile()
        }
    }
    repositories {
        maven {
            name "s3bucket"
            url "s3://BUCKET_NAME/snapshots"
            credentials(AwsCredentials) {
                accessKey awsCredentials.AWSAccessKeyId
                secretKey awsCredentials.AWSSecretKey
            }
        }
    }
}
```

Soll wie im Beispiel ein S3-Bucket als Ziel verwendet werden, müssen die entsprechenden Credentials in den
Umgebungsvariablen `AWS_ACCESS_KEY_ID` und `AWS_SECRET_ACCESS_KEY` hinterlegt sein.

Die Veröffentlichung wird dann wie folgt ausgelöst:
```bash
gradle publish                   # -> de.customer:MyProject:devel-SNAPSHOT
gradle publish -Penv=staging     # -> de.customer:MyProject:staging-SNAPSHOT
gradle publish -Penv=prod        # -> de.customer:MyProject:prod-SNAPSHOT
```

## Buildskript aktualisieren

Alle UM-spezifischen Gradle-Tasks sind in `.umstarter.gradle` implementiert.
Diese Datei kann wie folgt auf den neusten Stand gebracht werden:
```bash
gradle updateBuildScript
```

## Docker-Image bauen

Für das Deployment auf einem Staging- oder Produktivsystem kann ein Dockerimage gebaut werden -- z.B. für die _prod_-Umgebung:
```bash
gradle dockerimage -Penv=prod
```
Das _Tag_ des erzeugten Images setzt sich dabei zusammen aus dem Wert der Variablen
`pinuts.docker.tag` (Fallback auf `pinuts.projectName` in lowercase) und dem Namen der Umgebung, z.B. also `myproject:prod`.

Von diesem Image kann man dann einen Container starten, z.B.:
```bash
docker run --rm -p 8080:8080 myproject:prod
```

## Testing
To be documented...
```groovy
test.dependsOn << testDriver_umci // TestDriver automatisch anstarten
```
