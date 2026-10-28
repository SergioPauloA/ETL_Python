# Data Warehouse AdventureWorks com Apache Airflow

Projeto individual da disciplina de Engenharia de Dados (Unisales).
Data Warehouse de **Vendas** em **PostgreSQL**, modelado em **Star Schema**, populado por uma
**ETL incremental** orquestrada pelo **Apache Airflow**, a partir do banco OLTP AdventureWorks.

## Visão geral

| Item | Descrição |
|---|---|
| Origem (OLTP) | AdventureWorks (PostgreSQL) — schemas `sales`, `production`, `person` |
| Destino (DW) | PostgreSQL, schema `dw` (1 fato + 6 dimensões) |
| Granularidade da fato | 1 linha por **item de pedido** (`SalesOrderDetail`) |
| ETL | Airflow, DAG `dw_adventureworks_etl` |
| Incremental | *Watermark* em `dw.etl_controle` + `ModifiedDate` + UPSERT |
| Conexões | IDs nomeados no Airflow: `aw_oltp` e `dw_postgres` (sem credenciais em arquivos) |

## Estrutura

```
dags/
  dw_adventureworks_etl.py   # DAG (definição das tasks e dependências)
  etl_utils.py               # funções de extração, carga, watermark e validação
sql/
  ddl/                       # criação do DW (schema, dimensões, fato, staging, dim_tempo)
  extract/                   # queries de extração incremental no OLTP (uma por tabela)
  load/                      # SQL de carga da fato (lookup de chaves + UPSERT)
  kpis/                      # os 10 indicadores
  demo/                      # script que altera o OLTP para demonstrar a carga incremental
scripts/
  carregar_adventureworks.sh # carga do AdventureWorks (Linux/macOS/WSL); no Windows veja abaixo
  executar_kpis.sh           # roda os 10 KPIs no DW
docs/
  modelo_estrela.png / .dot  # diagrama do Star Schema
  dag_fluxo.png / .dot       # diagrama do fluxo da DAG
  dicionario_dados.md        # dicionário de dados do DW
  evidencias/                # logs reais das execuções e resultados dos KPIs
docker-compose.yml  .env.example (sem credenciais)  .gitignore
```

## Como executar

### Credenciais e conexões (sem login/senha em arquivos)
- O `.env` está no `.gitignore` e **não contém login nem senha** (`.env.example` só traz `AIRFLOW_UID`, opcional).
- O Airflow acessa os bancos por **conexões com ID nomeado**: `aw_oltp` (origem) e `dw_postgres` (destino).
  O `docker-compose.yml` as cadastra no Airflow na subida; elas podem ser vistas/editadas em
  **Admin > Connections** ou via CLI (`airflow connections get aw_oltp`).
- Os bancos do `docker-compose` são locais, com autenticação `trust` e portas expostas só em `127.0.0.1`.
  **Isso é apenas para estudo/uso local.** Em produção, use senhas e um *secrets backend*.
- A senha do usuário `admin` do Airflow é gerada no primeiro start e salva em `logs/admin_login.txt` (pasta ignorada pelo Git).

### 1. Subir o ambiente
```bash
docker compose up -d
```
Airflow: <http://localhost:8080>. Login: veja `logs/admin_login.txt`
(PowerShell: `Get-Content logs\admin_login.txt`).
Se perder a senha: `docker compose exec airflow airflow users reset-password --username admin`.

### 2. Carregar o AdventureWorks no banco OLTP
**Linux/macOS/WSL** (requer curl, unzip, ruby e psql):
```bash
./scripts/carregar_adventureworks.sh
```
**Windows/PowerShell** (tudo via containers):
```powershell
mkdir aw_data; cd aw_data
Invoke-WebRequest https://github.com/microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks-oltp-install-script.zip -OutFile aw.zip
Expand-Archive aw.zip -DestinationPath . -Force
Invoke-WebRequest https://raw.githubusercontent.com/lorint/AdventureWorks-for-Postgres/master/install.sql -OutFile install.sql
Invoke-WebRequest https://raw.githubusercontent.com/lorint/AdventureWorks-for-Postgres/master/update_csvs.rb -OutFile update_csvs.rb
docker run --rm -v "${PWD}:/data" -w /data ruby:3.3 ruby update_csvs.rb
cd ..
docker compose cp aw_data postgres-oltp:/aw_data
docker compose exec -w /aw_data postgres-oltp psql -q -U postgres -d Adventureworks -f install.sql
docker compose exec postgres-oltp psql -U postgres -d Adventureworks -c "select count(*) from sales.salesorderdetail"   # esperado: 121317
Remove-Item -Recurse -Force aw_data
```
(No `psql`, aperte `q` para sair do paginador.) Se a disciplina já forneceu o AdventureWorks em PostgreSQL, basta ajustar a conexão `aw_oltp` em Admin > Connections.

### 3. Executar a DAG
Na interface do Airflow: ative (unpause) a `dw_adventureworks_etl` e clique em **Trigger DAG**.
A primeira execução faz a carga completa (~121 mil itens). A estrutura do DW é criada pela própria
DAG (task `garantir_estrutura`).

### 4. Demonstrar a carga incremental
1. Rode a DAG novamente **sem** alterar nada: todas as tasks de carga informam 0 linhas.
2. Aplique as alterações no OLTP (PowerShell):
   `Get-Content sql/demo/simular_alteracoes_oltp.sql | docker compose exec -T postgres-oltp psql -U postgres -d Adventureworks`
   (Linux/macOS: `docker compose exec -T postgres-oltp psql -U postgres -d Adventureworks < sql/demo/simular_alteracoes_oltp.sql`)
3. Rode a DAG de novo: apenas 1 produto, 1 oferta e 15 itens de pedido são processados.

### 5. Calcular os indicadores
Linux/macOS: `./scripts/executar_kpis.sh`. PowerShell, para cada arquivo:
`Get-Content sql/kpis/01_receita_liquida_total.sql | docker compose exec -T postgres-dw psql -U postgres -d dw_adventureworks`

## Estratégia de ETL incremental

1. `ler_watermark` lê `dw.etl_controle.ultima_carga` de cada tabela.
2. Cada `load_*` extrai do OLTP só registros com `ModifiedDate > watermark`.
3. Dimensões: UPSERT (`ON CONFLICT (chave_natural) DO UPDATE`) — SCD Tipo 1.
4. Fato: dados vão para `stg_fact_vendas`; um único SQL resolve as chaves substitutas e faz UPSERT.
   Um item é reprocessado se o **item ou o cabeçalho** do pedido foi alterado.
5. `atualizar_watermark` só executa se todas as cargas tiveram sucesso.
6. `validar_carga` reconcilia contagem e valor líquido entre OLTP e DW.

## Limitações conhecidas
- Exclusões físicas no OLTP não são propagadas (a extração se baseia em `ModifiedDate`).
- Dimensões em SCD Tipo 1 não guardam histórico de atributos; `custo_total` usa o custo padrão vigente no momento da carga.
- O watermark usa comparação estrita (`>`); registros com timestamp idêntico ao limite e gravados depois da carga não seriam capturados.
