-- KPI 01 - Receita líquida total
-- Fórmula: SUM(valor_liquido) = SUM(qtd * preço unitário * (1 - desconto))
-- Granularidade da análise: total geral e por ano.
SELECT COALESCE(t.ano::text, 'TOTAL')        AS ano,
       ROUND(SUM(f.valor_liquido), 2)        AS receita_liquida
FROM dw.fact_vendas f
JOIN dw.dim_tempo   t ON t.sk_tempo = f.sk_tempo
GROUP BY ROLLUP (t.ano)
ORDER BY t.ano NULLS LAST;
