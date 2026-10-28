#!/usr/bin/env bash
# Carrega o AdventureWorks (versão PostgreSQL de lorint) no container postgres-oltp.
# Pré-requisitos no seu computador: curl, unzip, ruby, psql. (Usuários de Windows: veja README, seção "Windows/PowerShell".)
# Uso: ./scripts/carregar_adventureworks.sh
set -euo pipefail
WORK="$(mktemp -d)"; cd "$WORK"
echo ">> Baixando AdventureWorks..."
curl -sSL -o aw.zip "https://github.com/microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks-oltp-install-script.zip"
unzip -q aw.zip
curl -sSL -O "https://raw.githubusercontent.com/lorint/AdventureWorks-for-Postgres/master/install.sql"
curl -sSL -O "https://raw.githubusercontent.com/lorint/AdventureWorks-for-Postgres/master/update_csvs.rb"
echo ">> Convertendo CSVs..."; ruby update_csvs.rb
echo ">> Carregando no banco (localhost:5433, autenticação trust, sem senha)..."
psql -q -h 127.0.0.1 -p 5433 -U postgres -d Adventureworks -f install.sql
psql -h 127.0.0.1 -p 5433 -U postgres -d Adventureworks -c "SELECT COUNT(*) AS itens_de_pedido FROM sales.salesorderdetail;"
echo ">> Esperado: 121317"
