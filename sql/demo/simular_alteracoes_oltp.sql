-- =====================================================================
-- DEMONSTRAÇÃO DA CARGA INCREMENTAL
-- Execute no banco OLTP (Adventureworks) DEPOIS da carga inicial.
-- Em seguida dispare a DAG novamente: ela deve processar APENAS
-- as linhas abaixo (e não os 121 mil itens de novo).
-- =====================================================================

-- 1) Registros ALTERADOS: desconto em 3 itens do pedido 43659
UPDATE sales.salesorderdetail
   SET unitpricediscount = 0.05,
       modifieddate      = now()
 WHERE salesorderid = 43659
   AND salesorderdetailid IN (1, 2, 3);

-- 2) Dimensão ALTERADA (SCD Tipo 1): reajuste de preço de lista do produto 707
UPDATE production.product
   SET listprice    = listprice * 1.10,
       modifieddate = now()
 WHERE productid = 707;

-- 3) Registro NOVO na dimensão: nova oferta especial
--    (ID explícito = max+1, pois as sequences podem não estar sincronizadas após a carga dos CSVs)
INSERT INTO sales.specialoffer
       (specialofferid, description, discountpct, type, category, startdate, enddate, minqty, maxqty, rowguid, modifieddate)
SELECT COALESCE(MAX(specialofferid), 0) + 1, 'Promocao Demo Incremental', 0.15, 'Seasonal Discount', 'Reseller',
       now(), now() + interval '30 days', 0, NULL, gen_random_uuid(), now()
  FROM sales.specialoffer;

-- 4) Registros NOVOS na fato: um pedido novo (cópia do pedido 43659 com data de hoje)
WITH novo AS (
    INSERT INTO sales.salesorderheader
           (salesorderid, revisionnumber, orderdate, duedate, shipdate, status, onlineorderflag,
            customerid, salespersonid, territoryid, billtoaddressid, shiptoaddressid,
            shipmethodid, subtotal, taxamt, freight, rowguid, modifieddate)
    SELECT (SELECT MAX(salesorderid) + 1 FROM sales.salesorderheader),
           revisionnumber, now(), now() + interval '7 days', NULL, status, onlineorderflag,
           customerid, salespersonid, territoryid, billtoaddressid, shiptoaddressid,
           shipmethodid, subtotal, taxamt, freight, gen_random_uuid(), now()
      FROM sales.salesorderheader
     WHERE salesorderid = 43659
    RETURNING salesorderid
)
INSERT INTO sales.salesorderdetail
       (salesorderid, salesorderdetailid, carriertrackingnumber, orderqty, productid, specialofferid,
        unitprice, unitpricediscount, rowguid, modifieddate)
SELECT n.salesorderid,
       (SELECT MAX(salesorderdetailid) FROM sales.salesorderdetail) + ROW_NUMBER() OVER (ORDER BY d.salesorderdetailid),
       d.carriertrackingnumber, d.orderqty, d.productid, d.specialofferid,
       d.unitprice, d.unitpricediscount, gen_random_uuid(), now()
  FROM novo n
  JOIN sales.salesorderdetail d ON d.salesorderid = 43659;
