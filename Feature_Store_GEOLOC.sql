CREATE OR REPLACE TEMP VIEW tb_base_seller_orders AS

WITH tb_pedidos AS (
  SELECT *
  FROM bronze.olist.orders
  WHERE order_purchase_timestamp < '2018-07-01'
),

tb_itens_pedidos_periodo AS (
  SELECT
    p.order_id,
    p.customer_id,
    p.order_purchase_timestamp,
    DATE(p.order_purchase_timestamp) AS order_date,
    DATE_TRUNC('month', p.order_purchase_timestamp) AS order_month,

    i.seller_id,

    SUM(i.price) AS receita_produto,
    SUM(i.freight_value) AS receita_frete,
    SUM(i.price + i.freight_value) AS receita_total

  FROM tb_pedidos p

  INNER JOIN bronze.olist.order_items i
    ON p.order_id = i.order_id

  GROUP BY
    p.order_id,
    p.customer_id,
    p.order_purchase_timestamp,
    DATE(p.order_purchase_timestamp),
    DATE_TRUNC('month', p.order_purchase_timestamp),
    i.seller_id
),

tb_geo AS (
  SELECT
    geolocation_zip_code_prefix,
    AVG(geolocation_lat) AS latitude,
    AVG(geolocation_lng) AS longitude
  FROM bronze.olist.geolocation
  GROUP BY geolocation_zip_code_prefix
)

SELECT
  s.seller_id,

  s.seller_zip_code_prefix,
  s.seller_city,
  s.seller_state,

  i.order_id,
  i.customer_id,
  i.order_purchase_timestamp,
  i.order_date,
  i.order_month,

  c.customer_zip_code_prefix,
  c.customer_city,
  c.customer_state,

  COALESCE(i.receita_produto, 0) AS receita_produto,
  COALESCE(i.receita_frete, 0) AS receita_frete,
  COALESCE(i.receita_total, 0) AS receita_total,

  geo_seller.latitude AS seller_latitude,
  geo_seller.longitude AS seller_longitude,

  geo_customer.latitude AS customer_latitude,
  geo_customer.longitude AS customer_longitude,

  CASE
    WHEN s.seller_state IN ('AM','RR','AP','PA','TO','RO','AC') THEN 'Norte'
    WHEN s.seller_state IN ('MA','PI','CE','RN','PB','PE','AL','SE','BA') THEN 'Nordeste'
    WHEN s.seller_state IN ('MT','MS','GO','DF') THEN 'Centro-Oeste'
    WHEN s.seller_state IN ('SP','RJ','MG','ES') THEN 'Sudeste'
    WHEN s.seller_state IN ('PR','SC','RS') THEN 'Sul'
    ELSE 'Não identificado'
  END AS regiao_seller,

  CASE
    WHEN UPPER(s.seller_city) IN (
      'RIO BRANCO', 'MACEIO', 'MACAPA', 'MANAUS', 'SALVADOR',
      'FORTALEZA', 'BRASILIA', 'VITORIA', 'GOIANIA', 'SAO LUIS',
      'CUIABA', 'CAMPO GRANDE', 'BELO HORIZONTE', 'BELEM',
      'JOAO PESSOA', 'CURITIBA', 'RECIFE', 'TERESINA',
      'RIO DE JANEIRO', 'NATAL', 'PORTO ALEGRE', 'PORTO VELHO',
      'BOA VISTA', 'FLORIANOPOLIS', 'SAO PAULO', 'ARACAJU', 'PALMAS'
    ) THEN 1
    ELSE 0
  END AS flag_seller_capital,

  CASE
    WHEN i.order_id IS NOT NULL
     AND geo_seller.latitude IS NOT NULL
     AND geo_seller.longitude IS NOT NULL
     AND geo_customer.latitude IS NOT NULL
     AND geo_customer.longitude IS NOT NULL
    THEN ROUND(6371 * 2 * ASIN(
      SQRT(
        POWER(SIN(RADIANS(geo_customer.latitude - geo_seller.latitude) / 2), 2)
        +
        COS(RADIANS(geo_seller.latitude))
        * COS(RADIANS(geo_customer.latitude))
        * POWER(SIN(RADIANS(geo_customer.longitude - geo_seller.longitude) / 2), 2)
      )
    ))
    ELSE NULL
  END AS distancia_km

FROM bronze.olist.sellers s

LEFT JOIN tb_itens_pedidos_periodo i
  ON s.seller_id = i.seller_id

LEFT JOIN bronze.olist.customers c
  ON i.customer_id = c.customer_id

LEFT JOIN tb_geo geo_seller
  ON s.seller_zip_code_prefix = geo_seller.geolocation_zip_code_prefix

LEFT JOIN tb_geo geo_customer
  ON c.customer_zip_code_prefix = geo_customer.geolocation_zip_code_prefix;
