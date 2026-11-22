#!/bin/bash
set -euo pipefail
# als user postgres
# tree_species_view haengt von tree_species ab; ohne DROP scheitert DROP TABLE in tree_species.sql
psql -v ON_ERROR_STOP=1 -d themeparktest -c "DROP VIEW IF EXISTS tree_species_view;"
psql -v ON_ERROR_STOP=1 -d themeparktest -a -f /home/renderaccount/Mymapnik_openstreetmap-carto/Server_Update/tree_species.sql
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
psql -v ON_ERROR_STOP=1 -d themeparktest -a -f "$script_dir/tree_species_view.sql"
