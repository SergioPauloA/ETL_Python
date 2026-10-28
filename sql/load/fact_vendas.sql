-- =====================================================================
-- Carga da fato a partir do staging: resolve chaves substitutas
-- (lookup nas dimensões) e faz UPSERT idempotente.
-- Chave não encontrada => membro -1 (Desconhecido).
-- =====================================================================
INSERT INTO dw.fact_vendas (
    id_pedido, id_item_pedido, venda_online,
    sk_tempo, sk_produto, sk_cliente, sk_territorio, sk_vendedor, sk_oferta,
    quantidade, preco_unitario, pct_desconto,
    valor_bruto, valor_desconto, valor_liquido, custo_total,
    dt_modificacao_origem, dt_carga
)
SELECT
    s.id_pedido, s.id_item_pedido, s.venda_online,
    to_char(s.data_pedido, 'YYYYMMDD')::int,
    COALESCE(p.sk_produto,    -1),
    COALESCE(c.sk_cliente,    -1),
    COALESCE(t.sk_territorio, -1),
    COALESCE(v.sk_vendedor,   -1),
    COALESCE(o.sk_oferta,     -1),
    s.quantidade, s.preco_unitario, s.pct_desconto,
    ROUND(s.quantidade * s.preco_unitario, 4),
    ROUND(s.quantidade * s.preco_unitario * s.pct_desconto, 4),
    ROUND(s.quantidade * s.preco_unitario * (1 - s.pct_desconto), 4),
    ROUND(s.quantidade * COALESCE(p.custo_padrao, 0), 4),
    s.dt_modificacao_origem, now()
FROM dw.stg_fact_vendas s
LEFT JOIN dw.dim_produto         p ON p.id_produto   = s.id_produto
LEFT JOIN dw.dim_cliente         c ON c.id_cliente   = s.id_cliente
LEFT JOIN dw.dim_territorio      t ON t.id_territorio = s.id_territorio
LEFT JOIN dw.dim_vendedor        v ON v.id_vendedor  = s.id_vendedor
LEFT JOIN dw.dim_oferta_especial o ON o.id_oferta    = s.id_oferta
ON CONFLICT (id_pedido, id_item_pedido) DO UPDATE SET
    venda_online          = EXCLUDED.venda_online,
    sk_tempo              = EXCLUDED.sk_tempo,
    sk_produto            = EXCLUDED.sk_produto,
    sk_cliente            = EXCLUDED.sk_cliente,
    sk_territorio         = EXCLUDED.sk_territorio,
    sk_vendedor           = EXCLUDED.sk_vendedor,
    sk_oferta             = EXCLUDED.sk_oferta,
    quantidade            = EXCLUDED.quantidade,
    preco_unitario        = EXCLUDED.preco_unitario,
    pct_desconto          = EXCLUDED.pct_desconto,
    valor_bruto           = EXCLUDED.valor_bruto,
    valor_desconto        = EXCLUDED.valor_desconto,
    valor_liquido         = EXCLUDED.valor_liquido,
    custo_total           = EXCLUDED.custo_total,
    dt_modificacao_origem = EXCLUDED.dt_modificacao_origem,
    dt_carga              = now();
