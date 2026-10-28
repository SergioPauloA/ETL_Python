-- KPI 09 - Valor total de desconto concedido e % sobre a receita bruta
-- Fórmula: SUM(valor_desconto) / SUM(valor_bruto) * 100
SELECT COALESCE(t.ano::text, 'TOTAL')                                          AS ano,
       ROUND(SUM(f.valor_bruto), 2)                                            AS receita_bruta,
       ROUND(SUM(f.valor_desconto), 2)                                         AS desconto_total,
       ROUND(SUM(f.valor_desconto) / NULLIF(SUM(f.valor_bruto), 0) * 100, 2)   AS desconto_pct
FROM dw.fact_vendas f
JOIN dw.dim_tempo   t ON t.sk_tempo = f.sk_tempo
GROUP BY ROLLUP (t.ano)
ORDER BY t.ano NULLS LAST;
