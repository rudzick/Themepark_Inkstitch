#!/bin/bash
set -euo pipefail
# als user postgres
psql -v ON_ERROR_STOP=1 -d themeparktest -a -f /home/renderaccount/Myosm2pgsql-themepark/Server_Update/allotment_plot_entrances.sql



