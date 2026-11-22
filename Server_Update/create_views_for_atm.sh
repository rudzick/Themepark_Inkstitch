#!/bin/bash
set -euo pipefail
# als user postgres
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
psql -v ON_ERROR_STOP=1 -d themeparktest -a -f "$script_dir/views_for_atm.sql"



