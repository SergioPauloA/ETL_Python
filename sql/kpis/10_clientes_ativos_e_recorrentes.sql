-- KPI 10 - Clientes ativos e recorrentes por ano
-- Ativo      : cliente com ao menos 1 pedido no ano.
-- Recorrente : cliente com 2 ou mais pedidos distintos no ano.
WITH pedidos_cliente AS (
    SELECT t.ano,
           f.sk_cliente,
           COUNT(DISTINCT f.id_pedido) AS qtd_pedidos
    FROM dw.fact_vendas f
    JOIN dw.dim_tempo   t ON t.sk_tempo = f.sk_tempo
    GROUP BY t.ano, f.sk_cliente
)
SELECT ano,
       COUNT(*)                                                       AS clientes_ativos,
       COUNT(*) FILTER (WHERE qtd_pedidos >= 2)                       AS clientes_recorrentes,
       ROUND(COUNT(*) FILTER (WHERE qtd_pedidos >= 2) * 100.0 / COUNT(*), 2) AS recorrencia_pct
FROM pedidos_cliente
GROUP BY ano
ORDER BY ano;
