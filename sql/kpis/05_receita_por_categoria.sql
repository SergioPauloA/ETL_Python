-- KPI 05 - Receita líquida por categoria de produto (com participação %)
SELECT p.categoria,
       ROUND(SUM(f.valor_liquido), 2)                                          AS receita_liquida,
       ROUND(SUM(f.valor_liquido) * 100.0 / SUM(SUM(f.valor_liquido)) OVER (), 2) AS participacao_pct
FROM dw.fact_vendas f
JOIN dw.dim_produto p ON p.sk_produto = f.sk_produto
GROUP BY p.categoria
ORDER BY receita_liquida DESC;
