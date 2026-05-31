%sql
WITH params AS (
    SELECT
        DATE('2017-08-01') AS date_ref,
        DATE_ADD(DATE('2017-08-01'), 28) AS periodo
), 

periodo as (
SELECT DISTINCT
    s.seller_id,
    i.order_id
FROM olist.sellers s
LEFT JOIN workspace.olist.items i on s.seller_id = i.seller_id
LEFT JOIN olist.orders o on i.order_id = o.order_id
CROSS JOIN params p
WHERE o.order_purchase_timestamp BETWEEN p.date_ref AND p.periodo
),

periodo_vendas as (
SELECT 
    seller_id,
    COUNT(*) as total_pedidos_periodo
FROM periodo
GROUP BY seller_id),

vendas as (
SELECT DISTINCT
    s.seller_id,
    i.order_id
FROM olist.sellers s
LEFT JOIN workspace.olist.items i on s.seller_id = i.seller_id
LEFT JOIN olist.orders o on i.order_id = o.order_id
CROSS JOIN params p
WHERE o.order_purchase_timestamp < p.date_ref
),

total_vendas as (
    SELECT 
    seller_id,
    COUNT(*) as total_pedidos
FROM vendas
GROUP BY seller_id
)

select 
    t.seller_id,
    round(total_pedidos_periodo/total_pedidos,2) as prop_pedidos_periodo
from total_vendas t
inner join periodo_vendas p on t.seller_id = p.seller_id
