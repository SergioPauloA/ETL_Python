-- Extração incremental: Oferta especial (promoção)
SELECT
    o.specialofferid       AS id_oferta,
    o.description          AS descricao,
    o.discountpct          AS pct_desconto,
    o.type                 AS tipo,
    o.category             AS categoria,
    o.startdate::date      AS data_inicio,
    o.enddate::date        AS data_fim,
    o.minqty               AS qtd_minima,
    o.maxqty               AS qtd_maxima,
    o.modifieddate         AS dt_modificacao_origem
FROM sales.specialoffer o
WHERE o.modifieddate > %(wm)s
