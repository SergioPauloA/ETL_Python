-- Extração incremental: Vendedor (SalesPerson + Person)
SELECT
    sp.businessentityid                                        AS id_vendedor,
    COALESCE(NULLIF(TRIM(CONCAT_WS(' ', p.firstname, p.lastname)), ''),
             'Vendedor ' || sp.businessentityid::text)         AS nome_vendedor,
    COALESCE(sp.salesquota, 0)                                 AS cota_vendas,
    COALESCE(sp.bonus, 0)                                      AS bonus,
    COALESCE(sp.commissionpct, 0)                              AS pct_comissao,
    GREATEST(sp.modifieddate, p.modifieddate)                  AS dt_modificacao_origem
FROM sales.salesperson sp
LEFT JOIN person.person p ON p.businessentityid = sp.businessentityid
WHERE GREATEST(sp.modifieddate, p.modifieddate) > %(wm)s
