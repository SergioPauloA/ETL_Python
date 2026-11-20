SELECT COALESCE(p.categoria, 'TOTAL')                                          AS categoria,
       ROUND(SUM(f.valor_liquido), 2)                                          AS receita_liquida,
       ROUND(SUM(f.custo_total), 2)                                            AS custo_total,
       ROUND(SUM(f.valor_liquido) - SUM(f.custo_total), 2)                     AS margem_bruta,
       ROUND((SUM(f.valor_liquido) - SUM(f.custo_total))
             / NULLIF(SUM(f.valor_liquido), 0) * 100, 2)                       AS margem_bruta_pct
FROM dw.fact_vendas f
JOIN dw.dim_produto p ON p.sk_produto = f.sk_produto
GROUP BY ROLLUP (p.categoria)
ORDER BY receita_liquida DESC;
