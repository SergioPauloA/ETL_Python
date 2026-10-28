-- KPI 04 - Margem bruta (%)
-- Fórmula: (SUM(valor_liquido) - SUM(custo_total)) / SUM(valor_liquido) * 100
-- Observação: custo_total usa o custo padrão do produto (SCD Tipo 1).
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
