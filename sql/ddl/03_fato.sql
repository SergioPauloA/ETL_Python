-- =====================================================================
-- 03 - Tabela fato e tabela de staging
-- GRANULARIDADE: uma linha por ITEM de pedido de venda
--                (Sales.SalesOrderDetail), identificada por
--                (id_pedido, id_item_pedido).
-- =====================================================================
CREATE TABLE IF NOT EXISTS dw.fact_vendas (
    sk_venda              BIGSERIAL PRIMARY KEY,

    -- Dimensão degenerada (identificadores do documento de origem)
    id_pedido             INTEGER   NOT NULL,
    id_item_pedido        INTEGER   NOT NULL,
    venda_online          BOOLEAN   NOT NULL,

    -- Chaves estrangeiras para as dimensões
    sk_tempo              INTEGER   NOT NULL REFERENCES dw.dim_tempo(sk_tempo),
    sk_produto            INTEGER   NOT NULL REFERENCES dw.dim_produto(sk_produto),
    sk_cliente            INTEGER   NOT NULL REFERENCES dw.dim_cliente(sk_cliente),
    sk_territorio         INTEGER   NOT NULL REFERENCES dw.dim_territorio(sk_territorio),
    sk_vendedor           INTEGER   NOT NULL REFERENCES dw.dim_vendedor(sk_vendedor),
    sk_oferta             INTEGER   NOT NULL REFERENCES dw.dim_oferta_especial(sk_oferta),

    -- Medidas
    quantidade            INTEGER        NOT NULL,   -- aditiva
    preco_unitario        NUMERIC(19,4)  NOT NULL,   -- não aditiva
    pct_desconto          NUMERIC(6,4)   NOT NULL,   -- não aditiva
    valor_bruto           NUMERIC(19,4)  NOT NULL,   -- aditiva  = qtd * preço
    valor_desconto        NUMERIC(19,4)  NOT NULL,   -- aditiva  = bruto * pct_desconto
    valor_liquido         NUMERIC(19,4)  NOT NULL,   -- aditiva  = bruto - desconto
    custo_total           NUMERIC(19,4)  NOT NULL,   -- aditiva  = qtd * custo padrão

    -- Auditoria
    dt_modificacao_origem TIMESTAMP,
    dt_carga              TIMESTAMP NOT NULL DEFAULT now(),

    -- Chave natural: base do UPSERT (carga idempotente)
    CONSTRAINT uq_fact_vendas_nk UNIQUE (id_pedido, id_item_pedido)
);

CREATE INDEX IF NOT EXISTS ix_fact_vendas_tempo      ON dw.fact_vendas (sk_tempo);
CREATE INDEX IF NOT EXISTS ix_fact_vendas_produto    ON dw.fact_vendas (sk_produto);
CREATE INDEX IF NOT EXISTS ix_fact_vendas_cliente    ON dw.fact_vendas (sk_cliente);
CREATE INDEX IF NOT EXISTS ix_fact_vendas_territorio ON dw.fact_vendas (sk_territorio);
CREATE INDEX IF NOT EXISTS ix_fact_vendas_vendedor   ON dw.fact_vendas (sk_vendedor);
CREATE INDEX IF NOT EXISTS ix_fact_vendas_oferta     ON dw.fact_vendas (sk_oferta);

-- Staging: recebe o extrato bruto (chaves naturais) antes da resolução
-- das chaves substitutas. É esvaziada a cada execução.
CREATE UNLOGGED TABLE IF NOT EXISTS dw.stg_fact_vendas (
    id_pedido             INTEGER,
    id_item_pedido        INTEGER,
    data_pedido           DATE,
    id_produto            INTEGER,
    id_cliente            INTEGER,
    id_territorio         INTEGER,
    id_vendedor           INTEGER,
    id_oferta             INTEGER,
    venda_online          BOOLEAN,
    quantidade            INTEGER,
    preco_unitario        NUMERIC(19,4),
    pct_desconto          NUMERIC(6,4),
    dt_modificacao_origem TIMESTAMP
);
