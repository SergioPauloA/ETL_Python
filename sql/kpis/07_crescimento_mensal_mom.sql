-- KPI 07 - Crescimento mensal da receita (Month over Month)
-- Fórmula: (receita_mes - receita_mes_anterior) / receita_mes_anterior * 100
WITH mensal AS (
    SELECT t.ano_mes,
           SUM(f.valor_liquido) AS receita
    FROM dw.fact_vendas f
    JOIN dw.dim_tempo   t ON t.sk_tempo = f.sk_tempo
    GROUP BY t.ano_mes
)
SELECT ano_mes,
       ROUND(receita, 2)                                                       AS receita_liquida,
       ROUND(LAG(receita) OVER (ORDER BY ano_mes), 2)                          AS receita_mes_anterior,
       ROUND((receita - LAG(receita) OVER (ORDER BY ano_mes))
             / NULLIF(LAG(receita) OVER (ORDER BY ano_mes), 0) * 100, 2)       AS crescimento_mom_pct
FROM mensal
ORDER BY ano_mes;
