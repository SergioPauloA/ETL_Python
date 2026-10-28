-- Extração incremental: Itens de pedido (SalesOrderDetail) + cabeçalho (SalesOrderHeader).
-- Um item é reprocessado se o ITEM ou o CABEÇALHO do pedido foi modificado.
SELECT
    d.salesorderid                           AS id_pedido,
    d.salesorderdetailid                     AS id_item_pedido,
    h.orderdate::date                        AS data_pedido,
    d.productid                              AS id_produto,
    h.customerid                             AS id_cliente,
    COALESCE(h.territoryid, -1)              AS id_territorio,
    COALESCE(h.salespersonid, -1)            AS id_vendedor,
    COALESCE(d.specialofferid, -1)           AS id_oferta,
    h.onlineorderflag::boolean               AS venda_online,
    d.orderqty                               AS quantidade,
    d.unitprice                              AS preco_unitario,
    d.unitpricediscount                      AS pct_desconto,
    GREATEST(d.modifieddate, h.modifieddate) AS dt_modificacao_origem
FROM sales.salesorderdetail d
JOIN sales.salesorderheader h ON h.salesorderid = d.salesorderid
WHERE GREATEST(d.modifieddate, h.modifieddate) > %(wm)s
