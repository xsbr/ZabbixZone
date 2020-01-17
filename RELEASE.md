## Releasing a new version

### Before commit

* Update README.md

### After commit

* Tag the release commit: `git tag v0.9.2 && git push --tags`
* Add release at https://github.com/maxhq/zabbix-backup/releases

  **Summary of main changes**

  ```
This release fixes ...

### Direct download

[zabbix-mysql-dump](https://raw.githubusercontent.com/maxhq/zabbix-backup/v0.9.2/zabbix-dump) (v0.9.2)

### Changelog

Please see the [version history in the README](https://github.com/maxhq/zabbix-backup/blob/v0.9.2/README.md#version-history).

### Thanks!
- @username
  ```

* Update https://github.com/maxhq/zabbix-backup/wiki
* Update https://zabbix.org/wiki/Docs/howto/database_backup_script
* Announce release at https://www.linkedin.com/groups/161448

  > **New version x.x.x of zabbix-dump**
  >
  > zabbix-dump is a Linux bash script for backing up the Zabbix configuration by saving MySQL or PostgreSQL database tables into a compressed file.
  > Tables holding configuration data will be fully backed up. For mass data tables (events, history, trends, ...) only the table schema is stored without any data (to keep the backup small).
  >
  > Overiew: https://github.com/maxhq/zabbix-backup/blob/master/README.md
  > Latest release: https://github.com/maxhq/zabbix-backup/releases/latest

* Announce release at https://www.xing.com/communities/forums/100845147

  > **Neue Version x.x.x von zabbix-dump**
  >
  > zabbix-dump ist ein Linux-Bash-Skript zum Backup der Zabbix-Konfiguration durch Sicherung der MySQL- bzw. PostgreSQL-Datenbanktabellen in eine komprimierte Datei.
  > Es sichert Konfigurationsdaten komplett, bei Tabellen mit Massendaten (Historie, Events, Trends etc.) jedoch nur das "leere" Datenbankschema (um das Backup zu minimieren).
  >
  > Übersicht: https://github.com/maxhq/zabbix-backup/blob/master/README.md
  > Neueste Version: https://github.com/maxhq/zabbix-backup/releases/latest
