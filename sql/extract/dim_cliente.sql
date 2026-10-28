-- Extração incremental: Cliente (pessoa física ou loja)
SELECT
    c.customerid                                  AS id_cliente,
    CASE WHEN c.storeid IS NOT NULL THEN 'Loja' ELSE 'Pessoa' END AS tipo_cliente,
    COALESCE(
        s.name,
        NULLIF(TRIM(CONCAT_WS(' ', p.firstname, p.lastname)), ''),
        'Cliente ' || c.customerid::text
    )                                             AS nome_cliente,
    GREATEST(c.modifieddate, p.modifieddate, s.modifieddate) AS dt_modificacao_origem
FROM sales.customer c
LEFT JOIN person.person p ON p.businessentityid = c.personid
LEFT JOIN sales.store   s ON s.businessentityid = c.storeid
WHERE GREATEST(c.modifieddate, p.modifieddate, s.modifieddate) > %(wm)s
