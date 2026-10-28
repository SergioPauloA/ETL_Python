-- KPI 02 - Quantidade de itens vendidos
-- Fórmula: SUM(quantidade)
SELECT COALESCE(t.ano::text, 'TOTAL')  AS ano,
       SUM(f.quantidade)               AS quantidade_vendida
FROM dw.fact_vendas f
JOIN dw.dim_tempo   t ON t.sk_tempo = f.sk_tempo
GROUP BY ROLLUP (t.ano)
ORDER BY t.ano NULLS LAST;
