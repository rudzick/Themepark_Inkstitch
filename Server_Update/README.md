##### Skripte zum Aufbau und inkrementellen Update der Postgis-Datenbank `themeparktest` und zum Anlegen zusätzlicher Views

- Aufbau der Postgis-Datenbank mit osm2pgsql<br/>
[import_osm_planet_berlin_mapnik](import_osm_planet_berlin_mapnik)

- Inkrementelles Update der Postgis-Datenbank mit osm2pgsql-replication<br/>
[update_osm_planet_dach_mapnik](update_osm_planet_dach_mapnik)
   - systemd-Service und -Timer für das Update<br/>
[osm2pgsql_tp-update.service](osm2pgsql_tp-update.service), [osm2pgsql_tp-update.timer](osm2pgsql_tp-update.timer)

- Shellskript zur Erzeugung der View für Baum- und Straucharten<br/>
[create_tree_species_view.sh](create_tree_species_view.sh)
   - SQL für die View<br/>
[tree_species_view.sql](tree_species_view.sql)

- Shellskript zur Erzeugung der Views für Geldautomaten<br/>
[create_views_for_atm.sh](create_views_for_atm.sh)
   - SQL für die Views<br/>
[views_for_atm.sql](views_for_atm.sql)

- Shellskript zur Erzeugung der Eingänge von Kleingartenparzellen<br/>
[create_allotment_plot_entrances.sh](create_allotment_plot_entrances.sh)
   - SQL dazu<br/>
[allotment_plot_entrances.sql](allotment_plot_entrances.sql)

Die Shellskripte laufen als User `postgres`. Ihre SQL-Dateien laden sie aus
dem eigenen Verzeichnis. Mit `ON_ERROR_STOP` bricht ein Skript beim ersten
SQL-Fehler ab.

##### View `tree_species_view`

Die View fasst die Tabellen `trees` (`natural=tree`) und `shrubs`
(`natural=shrub`) aus dem Topic `shortbread_v1/trees_shrubs` zusammen und
ergänzt deutsche Artnamen.

| Spalte | Inhalt |
|---|---|
| `geom` | Punktgeometrie |
| `obstbaumart` | Erster vorhandener Wert aus `species:de`, deutschem Namen aus der Lookup-Tabelle `tree_species` (über `species`, Groß-/Kleinschreibung egal), `genus:de`, `species`, `genus` |
| `baumname` | `name:de`, sonst `name`, mit vorangestelltem Zeilenumbruch in „…“; leer, wenn kein Name vorhanden ist oder der Name `none` lautet |
| `tree_tags` | Alle OSM-Tags des Objekts unverändert als `jsonb` |
| `pflanzentyp` | `Baum` (aus `trees`) oder `Strauch` (aus `shrubs`) |

Die Lookup-Tabelle `tree_species` stammt aus dem Repo
[Mymapnik_openstreetmap-carto](https://github.com/rudzick/Mymapnik_openstreetmap-carto/blob/master/Server_Update/tree_species.sql).
[create_tree_species_view.sh](create_tree_species_view.sh) erwartet es unter
`/home/renderaccount/Mymapnik_openstreetmap-carto`. Das Skript löscht zuerst
die View, lädt dann `tree_species` neu und legt die View wieder an. Ohne das
Löschen scheitert das `DROP TABLE` in `tree_species.sql`, weil die View von der
Tabelle abhängt. Während das Skript läuft, ist die View kurz nicht vorhanden.
