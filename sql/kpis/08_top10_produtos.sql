-- KPI 08 - Top 10 produtos por receita líquida
SELECT RANK() OVER (ORDER BY SUM(f.valor_liquido) DESC)   AS posicao,
       p.nome                                             AS produto,
       p.categoria,
       SUM(f.quantidade)                                  AS quantidade_vendida,
       ROUND(SUM(f.valor_liquido), 2)                     AS receita_liquida
FROM dw.fact_vendas f
JOIN dw.dim_produto p ON p.sk_produto = f.sk_produto
GROUP BY p.nome, p.categoria
ORDER BY posicao
LIMIT 10;
