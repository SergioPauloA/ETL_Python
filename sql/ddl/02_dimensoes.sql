-- =====================================================================
-- 02 - Tabelas dimensão (Star Schema, dimensões desnormalizadas, SCD Tipo 1)
-- Cada dimensão possui:
--   sk_*  : chave substituta (surrogate key)
--   id_*  : chave natural vinda do OLTP (UNIQUE, usada no UPSERT)
-- O membro -1 representa "Desconhecido / Não se aplica" (evita FK nula na fato).
-- =====================================================================

-- ---------------------------- dim_tempo -------------------------------
CREATE TABLE IF NOT EXISTS dw.dim_tempo (
    sk_tempo           INTEGER PRIMARY KEY,          -- AAAAMMDD
    data               DATE        NOT NULL UNIQUE,
    ano                SMALLINT    NOT NULL,
    semestre           SMALLINT    NOT NULL,
    trimestre          SMALLINT    NOT NULL,
    mes                SMALLINT    NOT NULL,
    nome_mes           VARCHAR(15) NOT NULL,
    ano_mes            CHAR(7)     NOT NULL,         -- AAAA-MM
    dia                SMALLINT    NOT NULL,
    dia_semana         SMALLINT    NOT NULL,         -- 1=segunda ... 7=domingo
    nome_dia_semana    VARCHAR(15) NOT NULL,
    fim_de_semana      BOOLEAN     NOT NULL
);

-- ---------------------------- dim_produto -----------------------------
CREATE TABLE IF NOT EXISTS dw.dim_produto (
    sk_produto            SERIAL PRIMARY KEY,
    id_produto            INTEGER      NOT NULL UNIQUE,
    nome                  VARCHAR(100) NOT NULL,
    numero_produto        VARCHAR(30)  NOT NULL,
    cor                   VARCHAR(30)  NOT NULL,
    custo_padrao          NUMERIC(19,4) NOT NULL,
    preco_lista           NUMERIC(19,4) NOT NULL,
    id_subcategoria       INTEGER      NOT NULL,
    subcategoria          VARCHAR(60)  NOT NULL,
    id_categoria          INTEGER      NOT NULL,
    categoria             VARCHAR(60)  NOT NULL,
    dt_modificacao_origem TIMESTAMP,
    dt_carga              TIMESTAMP    NOT NULL DEFAULT now()
);

-- ---------------------------- dim_cliente -----------------------------
CREATE TABLE IF NOT EXISTS dw.dim_cliente (
    sk_cliente            SERIAL PRIMARY KEY,
    id_cliente            INTEGER      NOT NULL UNIQUE,
    tipo_cliente          VARCHAR(10)  NOT NULL,     -- 'Pessoa' ou 'Loja'
    nome_cliente          VARCHAR(160) NOT NULL,
    dt_modificacao_origem TIMESTAMP,
    dt_carga              TIMESTAMP    NOT NULL DEFAULT now()
);

-- ---------------------------- dim_territorio --------------------------
CREATE TABLE IF NOT EXISTS dw.dim_territorio (
    sk_territorio         SERIAL PRIMARY KEY,
    id_territorio         INTEGER      NOT NULL UNIQUE,
    nome_territorio       VARCHAR(60)  NOT NULL,
    codigo_pais           VARCHAR(10)  NOT NULL,
    grupo                 VARCHAR(60)  NOT NULL,
    dt_modificacao_origem TIMESTAMP,
    dt_carga              TIMESTAMP    NOT NULL DEFAULT now()
);

-- ---------------------------- dim_vendedor ----------------------------
CREATE TABLE IF NOT EXISTS dw.dim_vendedor (
    sk_vendedor           SERIAL PRIMARY KEY,
    id_vendedor           INTEGER      NOT NULL UNIQUE,
    nome_vendedor         VARCHAR(160) NOT NULL,
    cota_vendas           NUMERIC(19,4) NOT NULL DEFAULT 0,
    bonus                 NUMERIC(19,4) NOT NULL DEFAULT 0,
    pct_comissao          NUMERIC(6,4)  NOT NULL DEFAULT 0,
    dt_modificacao_origem TIMESTAMP,
    dt_carga              TIMESTAMP    NOT NULL DEFAULT now()
);

-- ---------------------------- dim_oferta_especial ---------------------
CREATE TABLE IF NOT EXISTS dw.dim_oferta_especial (
    sk_oferta             SERIAL PRIMARY KEY,
    id_oferta             INTEGER      NOT NULL UNIQUE,
    descricao             VARCHAR(255) NOT NULL,
    pct_desconto          NUMERIC(6,4) NOT NULL DEFAULT 0,
    tipo                  VARCHAR(50)  NOT NULL,
    categoria             VARCHAR(50)  NOT NULL,
    data_inicio           DATE,
    data_fim              DATE,
    qtd_minima            INTEGER,
    qtd_maxima            INTEGER,
    dt_modificacao_origem TIMESTAMP,
    dt_carga              TIMESTAMP    NOT NULL DEFAULT now()
);

-- ---------------------------- Membros "Desconhecido" (-1) -------------
INSERT INTO dw.dim_produto (sk_produto, id_produto, nome, numero_produto, cor, custo_padrao, preco_lista,
                            id_subcategoria, subcategoria, id_categoria, categoria)
VALUES (-1, -1, 'Desconhecido', 'N/D', 'N/D', 0, 0, -1, 'Desconhecido', -1, 'Desconhecido')
ON CONFLICT (sk_produto) DO NOTHING;

INSERT INTO dw.dim_cliente (sk_cliente, id_cliente, tipo_cliente, nome_cliente)
VALUES (-1, -1, 'Pessoa', 'Desconhecido')
ON CONFLICT (sk_cliente) DO NOTHING;

INSERT INTO dw.dim_territorio (sk_territorio, id_territorio, nome_territorio, codigo_pais, grupo)
VALUES (-1, -1, 'Desconhecido', 'N/D', 'Desconhecido')
ON CONFLICT (sk_territorio) DO NOTHING;

INSERT INTO dw.dim_vendedor (sk_vendedor, id_vendedor, nome_vendedor)
VALUES (-1, -1, 'Sem vendedor (venda online)')
ON CONFLICT (sk_vendedor) DO NOTHING;

INSERT INTO dw.dim_oferta_especial (sk_oferta, id_oferta, descricao, tipo, categoria)
VALUES (-1, -1, 'Sem oferta', 'N/D', 'N/D')
ON CONFLICT (sk_oferta) DO NOTHING;
