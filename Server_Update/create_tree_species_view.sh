#!/bin/bash
set -euo pipefail
# als user postgres
psql -d themeparktest -a -f /home/renderaccount/Mymapnik_openstreetmap-carto/Server_Update/tree_species.sql
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
psql -d themeparktest -a -f "$script_dir/tree_species_view.sql"
