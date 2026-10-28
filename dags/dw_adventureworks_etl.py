"""
DAG: dw_adventureworks_etl
Pipeline ETL incremental do Data Warehouse de Vendas (AdventureWorks -> PostgreSQL).

Fluxo:
  inicio -> garantir_estrutura -> ler_watermark
         -> [load_dim_produto, load_dim_cliente, load_dim_territorio,
             load_dim_vendedor, load_dim_oferta_especial]
         -> load_fact_vendas -> atualizar_watermark -> validar_carga -> fim

Conexões (Admin > Connections ou variáveis AIRFLOW_CONN_*):
  aw_oltp     -> banco AdventureWorks (origem)
  dw_postgres -> banco dw_adventureworks (destino)
"""
from datetime import timedelta

import pendulum
from airflow.decorators import dag, task
from airflow.operators.empty import EmptyOperator

import etl_utils as etl

default_args = {
    "owner": "aluno",
    "retries": 2,
    "retry_delay": timedelta(minutes=1),
}


@dag(
    dag_id="dw_adventureworks_etl",
    description="ETL incremental AdventureWorks -> DW (Star Schema) com watermark",
    schedule="@daily",
    start_date=pendulum.datetime(2024, 1, 1, tz="America/Sao_Paulo"),
    catchup=False,
    max_active_runs=1,          # evita duas cargas concorrentes mexendo no mesmo watermark
    default_args=default_args,
    tags=["dw", "adventureworks", "etl", "incremental"],
)
def dw_adventureworks_etl():

    @task
    def garantir_estrutura():
        """Cria schema, dimensões, fato, staging e dim_tempo (scripts idempotentes)."""
        etl.aplicar_ddl()

    @task
    def ler_watermark() -> dict:
        """Lê em dw.etl_controle até quando cada tabela já foi carregada."""
        return etl.ler_watermarks()

    @task
    def load_dimensao(tabela: str, watermarks: dict) -> dict:
        """Extract + Transform + Load (UPSERT, SCD Tipo 1) de uma dimensão."""
        return etl.carregar_dimensao(tabela, watermarks)

    @task
    def load_fact_vendas(watermarks: dict) -> dict:
        """Extrai itens novos/alterados, resolve chaves substitutas e faz UPSERT na fato."""
        return etl.carregar_fato(watermarks)

    @task
    def atualizar_watermark(resultados: list):
        """Avança o watermark apenas se TODAS as cargas anteriores tiveram sucesso."""
        etl.atualizar_watermarks(resultados)

    @task
    def validar_carga() -> dict:
        """Reconcilia contagem e valor líquido entre OLTP e DW."""
        return etl.validar_carga()

    inicio = EmptyOperator(task_id="inicio")
    fim = EmptyOperator(task_id="fim")

    estrutura = garantir_estrutura()
    marcas = ler_watermark()

    dimensoes = [
        load_dimensao.override(task_id=f"load_{tabela}")(tabela, marcas)
        for tabela in etl.DIMENSOES
    ]
    fato = load_fact_vendas(marcas)
    atualizado = atualizar_watermark(dimensoes + [fato])
    validacao = validar_carga()

    inicio >> estrutura >> marcas >> dimensoes >> fato >> atualizado >> validacao >> fim


dw_adventureworks_etl()
