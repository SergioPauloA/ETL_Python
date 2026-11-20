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
    max_active_runs=1,
    default_args=default_args,
    tags=["dw", "adventureworks", "etl", "incremental"],
)
def dw_adventureworks_etl():

    @task
    def garantir_estrutura():
        etl.aplicar_ddl()

    @task
    def ler_watermark() -> dict:
        return etl.ler_watermarks()

    @task
    def load_dimensao(tabela: str, watermarks: dict) -> dict:
        return etl.carregar_dimensao(tabela, watermarks)

    @task
    def load_fact_vendas(watermarks: dict) -> dict:
        return etl.carregar_fato(watermarks)

    @task
    def atualizar_watermark(resultados: list):
        etl.atualizar_watermarks(resultados)

    @task
    def validar_carga() -> dict:
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
