-- Extração incremental: Território de vendas
SELECT
    t.territoryid          AS id_territorio,
    t.name                 AS nome_territorio,
    t.countryregioncode    AS codigo_pais,
    t."group"              AS grupo,
    t.modifieddate         AS dt_modificacao_origem
FROM sales.salesterritory t
WHERE t.modifieddate > %(wm)s
