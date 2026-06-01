WITH tb_pedidos AS (
    SELECT *
    FROM workspace.olist.orders
    WHERE order_purchase_timestamp < '2018-07-01'
), -- aqui eu crio a tabela de pedidos filtrados antes do hoje.

tb_vendas AS (
    SELECT DISTINCT
           oi.seller_id,
           o.order_id,
           DATE(o.order_purchase_timestamp) AS dtVenda
    FROM tb_pedidos o
    INNER JOIN workspace.olist.order_items oi
        ON o.order_id = oi.order_id
), -- aqui eu crio a tabela de vendas filtradas antes do hoje.

tb_intervalos AS (
    SELECT
        seller_id,
        dtVenda,
        LAG(dtVenda) OVER (
            PARTITION BY seller_id
            ORDER BY dtVenda
        ) AS dtVendaAnterior
    FROM tb_vendas
),

tb_dias_entre_vendas AS (
    SELECT
        seller_id,
        DATEDIFF(
            day,
            dtVendaAnterior,
            dtVenda
        ) AS vlDiasEntreVendas
    FROM tb_intervalos
    WHERE dtVendaAnterior IS NOT NULL
) -- aqui eu crio a estrutura com o calculo do intervalo entre duas vendas consecutivas

SELECT -- aqui já é minha tabela com as métricas calculadas
    seller_id,

    AVG(vlDiasEntreVendas) AS vlDiasEntreVendasMedio,

    MIN(vlDiasEntreVendas) AS vlDiasEntreVendasMin,
    
    MAX(vlDiasEntreVendas) AS vlDiasEntreVendasMax,

    PERCENTILE_CONT(0.25)
        WITHIN GROUP (ORDER BY vlDiasEntreVendas)
        AS vlDiasEntreVendasP25,

    PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY vlDiasEntreVendas)
        AS vlDiasEntreVendasP50,

    PERCENTILE_CONT(0.75)
        WITHIN GROUP (ORDER BY vlDiasEntreVendas)
        AS vlDiasEntreVendasP75

FROM tb_dias_entre_vendas

GROUP BY seller_id

ORDER BY seller_id;