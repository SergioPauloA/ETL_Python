-- =====================================================================
-- 01 - Schema do Data Warehouse e tabela de controle da carga incremental
-- Idempotente: pode ser executado várias vezes sem efeito colateral.
-- =====================================================================
CREATE SCHEMA IF NOT EXISTS dw;

-- Tabela de controle (watermark): guarda até qual ModifiedDate da origem
-- cada tabela do DW já foi carregada.
CREATE TABLE IF NOT EXISTS dw.etl_controle (
    tabela           VARCHAR(60) PRIMARY KEY,
    ultima_carga     TIMESTAMP   NOT NULL DEFAULT '1900-01-01',
    ultima_execucao  TIMESTAMP,
    linhas_afetadas  INTEGER     NOT NULL DEFAULT 0
);

INSERT INTO dw.etl_controle (tabela) VALUES
    ('dim_produto'),
    ('dim_cliente'),
    ('dim_territorio'),
    ('dim_vendedor'),
    ('dim_oferta_especial'),
    ('fact_vendas')
ON CONFLICT (tabela) DO NOTHING;
