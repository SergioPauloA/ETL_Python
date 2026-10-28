-- Extração incremental: Produto + Subcategoria + Categoria (desnormalizado)
SELECT
    p.productid                                   AS id_produto,
    p.name                                        AS nome,
    p.productnumber                               AS numero_produto,
    COALESCE(p.color, 'N/D')                      AS cor,
    p.standardcost                                AS custo_padrao,
    p.listprice                                   AS preco_lista,
    COALESCE(sc.productsubcategoryid, -1)         AS id_subcategoria,
    COALESCE(sc.name, 'Sem subcategoria')         AS subcategoria,
    COALESCE(pc.productcategoryid, -1)            AS id_categoria,
    COALESCE(pc.name, 'Sem categoria')            AS categoria,
    GREATEST(p.modifieddate, sc.modifieddate, pc.modifieddate) AS dt_modificacao_origem
FROM production.product p
LEFT JOIN production.productsubcategory sc ON sc.productsubcategoryid = p.productsubcategoryid
LEFT JOIN production.productcategory     pc ON pc.productcategoryid    = sc.productcategoryid
WHERE GREATEST(p.modifieddate, sc.modifieddate, pc.modifieddate) > %(wm)s
