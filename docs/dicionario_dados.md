# Dicionário de dados — Data Warehouse de Vendas

Todas as tabelas estão no schema `dw`. Membro `-1` em cada dimensão = *Desconhecido / Não se aplica*.

## dw.fact_vendas

| Coluna | Tipo | Descrição | Origem (OLTP) |
|---|---|---|---|
| `sk_venda` | BIGSERIAL (PK) | Chave substituta da linha da fato | Gerada no DW |
| `sk_tempo` | INTEGER (FK) | Data do pedido (AAAAMMDD) | SalesOrderHeader.OrderDate |
| `sk_produto` | INTEGER (FK) | Produto vendido | SalesOrderDetail.ProductID |
| `sk_cliente` | INTEGER (FK) | Cliente que comprou | SalesOrderHeader.CustomerID |
| `sk_territorio` | INTEGER (FK) | Território de vendas | SalesOrderHeader.TerritoryID |
| `sk_vendedor` | INTEGER (FK) | Vendedor (-1 = venda online) | SalesOrderHeader.SalesPersonID |
| `sk_oferta` | INTEGER (FK) | Oferta especial aplicada (-1 = nenhuma) | SalesOrderDetail.SpecialOfferID |
| `id_pedido` | INTEGER | Nº do pedido (dimensão degenerada) | SalesOrderDetail.SalesOrderID |
| `id_item_pedido` | INTEGER | Nº do item no pedido (dimensão degenerada) | SalesOrderDetail.SalesOrderDetailID |
| `venda_online` | BOOLEAN | Indica pedido feito pela web | SalesOrderHeader.OnlineOrderFlag |
| `quantidade` | INTEGER | Unidades vendidas (aditiva) | SalesOrderDetail.OrderQty |
| `preco_unitario` | NUMERIC(19,4) | Preço unitário praticado (não aditiva) | SalesOrderDetail.UnitPrice |
| `pct_desconto` | NUMERIC(6,4) | Percentual de desconto do item (não aditiva) | SalesOrderDetail.UnitPriceDiscount |
| `valor_bruto` | NUMERIC(19,4) | quantidade × preço unitário (aditiva) | Calculada |
| `valor_desconto` | NUMERIC(19,4) | valor_bruto × pct_desconto (aditiva) | Calculada |
| `valor_liquido` | NUMERIC(19,4) | valor_bruto − valor_desconto (aditiva) | Calculada |
| `custo_total` | NUMERIC(19,4) | quantidade × custo padrão do produto (aditiva) | Calculada (Product.StandardCost) |
| `dt_modificacao_origem` | TIMESTAMP | Maior ModifiedDate entre item e cabeçalho | GREATEST(Detail, Header) |
| `dt_carga` | TIMESTAMP | Momento da última carga da linha | Gerada no DW |

## dw.dim_tempo

| Coluna | Tipo | Descrição | Origem (OLTP) |
|---|---|---|---|
| `sk_tempo` | INTEGER (PK) | Chave no formato AAAAMMDD | Gerada |
| `data` | DATE | Data completa | Gerada |
| `ano / semestre / trimestre / mes` | SMALLINT | Níveis da hierarquia temporal | Gerada |
| `nome_mes` | VARCHAR(15) | Nome do mês em português | Gerada |
| `ano_mes` | CHAR(7) | Período AAAA-MM (usado no MoM) | Gerada |
| `dia / dia_semana` | SMALLINT | Dia do mês e dia da semana (1=segunda) | Gerada |
| `nome_dia_semana` | VARCHAR(15) | Nome do dia da semana | Gerada |
| `fim_de_semana` | BOOLEAN | Sábado ou domingo | Gerada |

## dw.dim_produto

| Coluna | Tipo | Descrição | Origem (OLTP) |
|---|---|---|---|
| `sk_produto` | SERIAL (PK) | Chave substituta | Gerada no DW |
| `id_produto` | INTEGER (UNIQUE) | Chave natural | Product.ProductID |
| `nome / numero_produto` | VARCHAR | Nome e código do produto | Product.Name / ProductNumber |
| `cor` | VARCHAR(30) | Cor ('N/D' se nula) | Product.Color |
| `custo_padrao` | NUMERIC(19,4) | Custo padrão | Product.StandardCost |
| `preco_lista` | NUMERIC(19,4) | Preço de lista | Product.ListPrice |
| `id_subcategoria / subcategoria` | INTEGER / VARCHAR | Subcategoria (desnormalizada) | ProductSubcategory |
| `id_categoria / categoria` | INTEGER / VARCHAR | Categoria (desnormalizada) | ProductCategory |

## dw.dim_cliente

| Coluna | Tipo | Descrição | Origem (OLTP) |
|---|---|---|---|
| `sk_cliente` | SERIAL (PK) | Chave substituta | Gerada no DW |
| `id_cliente` | INTEGER (UNIQUE) | Chave natural | Customer.CustomerID |
| `tipo_cliente` | VARCHAR(10) | 'Loja' (StoreID preenchido) ou 'Pessoa' | Derivada de Customer.StoreID |
| `nome_cliente` | VARCHAR(160) | Nome da loja ou da pessoa | Store.Name / Person.FirstName+LastName |

## dw.dim_territorio

| Coluna | Tipo | Descrição | Origem (OLTP) |
|---|---|---|---|
| `sk_territorio` | SERIAL (PK) | Chave substituta | Gerada no DW |
| `id_territorio` | INTEGER (UNIQUE) | Chave natural | SalesTerritory.TerritoryID |
| `nome_territorio` | VARCHAR(60) | Nome do território | SalesTerritory.Name |
| `codigo_pais` | VARCHAR(10) | Código do país/região | SalesTerritory.CountryRegionCode |
| `grupo` | VARCHAR(60) | Grupo geográfico | SalesTerritory.Group |

## dw.dim_vendedor

| Coluna | Tipo | Descrição | Origem (OLTP) |
|---|---|---|---|
| `sk_vendedor` | SERIAL (PK) | Chave substituta | Gerada no DW |
| `id_vendedor` | INTEGER (UNIQUE) | Chave natural | SalesPerson.BusinessEntityID |
| `nome_vendedor` | VARCHAR(160) | Nome completo | Person.FirstName + LastName |
| `cota_vendas / bonus / pct_comissao` | NUMERIC | Atributos comerciais do vendedor | SalesPerson |

## dw.dim_oferta_especial

| Coluna | Tipo | Descrição | Origem (OLTP) |
|---|---|---|---|
| `sk_oferta` | SERIAL (PK) | Chave substituta | Gerada no DW |
| `id_oferta` | INTEGER (UNIQUE) | Chave natural | SpecialOffer.SpecialOfferID |
| `descricao / tipo / categoria` | VARCHAR | Descrição e classificação da promoção | SpecialOffer |
| `pct_desconto` | NUMERIC(6,4) | Percentual de desconto da oferta | SpecialOffer.DiscountPct |
| `data_inicio / data_fim` | DATE | Vigência da oferta | SpecialOffer.StartDate / EndDate |
| `qtd_minima / qtd_maxima` | INTEGER | Faixa de quantidade da oferta | SpecialOffer.MinQty / MaxQty |

## dw.etl_controle

| Coluna | Tipo | Descrição | Origem (OLTP) |
|---|---|---|---|
| `tabela` | VARCHAR(60) (PK) | Nome da tabela do DW controlada | — |
| `ultima_carga` | TIMESTAMP | Watermark: maior ModifiedDate já carregado | — |
| `ultima_execucao` | TIMESTAMP | Data/hora da última execução da DAG | — |
| `linhas_afetadas` | INTEGER | Linhas processadas na última execução | — |
