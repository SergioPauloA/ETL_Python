-- KPI 06 - Receita líquida por território de vendas (ranking e participação %)
SELECT RANK() OVER (ORDER BY SUM(f.valor_liquido) DESC)                        AS posicao,
       tr.nome_territorio,
       tr.grupo,
       ROUND(SUM(f.valor_liquido), 2)                                          AS receita_liquida,
       ROUND(SUM(f.valor_liquido) * 100.0 / SUM(SUM(f.valor_liquido)) OVER (), 2) AS participacao_pct
FROM dw.fact_vendas f
JOIN dw.dim_territorio tr ON tr.sk_territorio = f.sk_territorio
GROUP BY tr.nome_territorio, tr.grupo
ORDER BY posicao;
