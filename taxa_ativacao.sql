%sql
WITH params AS (
    SELECT DATE('2017-08-01') AS date_ref
)

SELECT 
    s.seller_id,

    round(COALESCE(
        TRY_DIVIDE(
            COUNT(DISTINCT o.order_purchase_timestamp),
            DATEDIFF(
                p.date_ref,
                MIN(DATE(o.order_purchase_timestamp))
            )
        ),
        0
    ),2) AS ativacao_por_dia

FROM olist.sellers s
CROSS JOIN params p
LEFT JOIN workspace.olist.items i 
    ON s.seller_id = i.seller_id
LEFT JOIN olist.orders o 
    ON i.order_id = o.order_id
WHERE o.order_purchase_timestamp < p.date_ref
GROUP BY s.seller_id, p.date_ref