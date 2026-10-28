-- KPI 03 - Ticket médio por pedido
-- Fórmula: SUM(valor_liquido) / COUNT(DISTINCT id_pedido)
SELECT COALESCE(t.ano::text, 'TOTAL')                                   AS ano,
       COUNT(DISTINCT f.id_pedido)                                      AS qtd_pedidos,
       ROUND(SUM(f.valor_liquido) / COUNT(DISTINCT f.id_pedido), 2)     AS ticket_medio
FROM dw.fact_vendas f
JOIN dw.dim_tempo   t ON t.sk_tempo = f.sk_tempo
GROUP BY ROLLUP (t.ano)
ORDER BY t.ano NULLS LAST;
