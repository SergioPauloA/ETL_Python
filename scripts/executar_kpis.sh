#!/usr/bin/env bash
# Executa os 10 SQLs de indicadores no DW (localhost:5434, sem senha).
# Uso: ./scripts/executar_kpis.sh
set -euo pipefail
for f in "$(dirname "$0")"/../sql/kpis/*.sql; do
  echo "=== $(basename "$f")"
  psql -h 127.0.0.1 -p 5434 -U postgres -d dw_adventureworks -f "$f"
done
