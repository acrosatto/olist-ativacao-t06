%sql
WITH tb_data AS (
    SELECT date('2018-07-01') as dt_referencia
),
tb_pedidos AS (
  SELECT *
  FROM workspace.olist.orders
  CROSS JOIN tb_data d
  WHERE order_purchase_timestamp < dt_referencia
),
tb_seller_rfv AS (
    select  
        s.seller_id,
        count(distinct p.order_id) as qtdPedidosVida,
        count(distinct case 
                        when datediff(d.dt_referencia, p.order_purchase_timestamp) <= 28 
                        then p.order_id end) as qtdPedidosD28,
        count(distinct case 
                        when datediff(d.dt_referencia, p.order_purchase_timestamp) <= 56 
                        then p.order_id end) as qtdPedidosD56,
        count(distinct case 
                        when datediff(d.dt_referencia, p.order_purchase_timestamp) <= 365 
                        then p.order_id end) as qtdPedidosD365,
        count(distinct case 
                        when order_status = 'delivered' 
                        then p.order_id end) as qtdPedidosDeliveredVida,
        count(distinct case 
                        when order_status = 'delivered' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 28 
                        then p.order_id end) as qtdPedidosDeliveredD28,
        count(distinct case 
                        when order_status = 'delivered' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 56 
                        then p.order_id end) as qtdPedidosDeliveredD56,
        count(distinct case 
                        when order_status = 'delivered' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 365 
                        then p.order_id end) as qtdPedidosDeliveredD365,
        count(distinct case 
                        when order_status = 'invoiced' 
                        then p.order_id end) as qtdPedidosInvoicedVida,
        count(distinct case 
                        when order_status = 'invoiced' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 28 
                        then p.order_id end) as qtdPedidosInvoicedD28,
        count(distinct case 
                        when order_status = 'invoiced' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 56 
                        then p.order_id end) as qtdPedidosInvoicedD56,
        count(distinct case 
                        when order_status = 'invoiced' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 365 
                        then p.order_id end) as qtdPedidosInvoicedD365,
        count(distinct case 
                        when order_status = 'shipped' 
                        then p.order_id end) as qtdPedidosShippedVida,
        count(distinct case 
                        when order_status = 'shipped' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 28 
                        then p.order_id end) as qtdPedidosShippedD28,
        count(distinct case 
                        when order_status = 'shipped' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 56 
                        then p.order_id end) as qtdPedidosShippedD56,
        count(distinct case 
                        when order_status = 'shipped' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 365 
                        then p.order_id end) as qtdPedidosShippedD365,
        count(distinct case 
                        when order_status = 'processing' 
                        then p.order_id end) as qtdPedidosProcessingVida,
        count(distinct case 
                        when order_status = 'processing' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 28 
                        then p.order_id end) as qtdPedidosProcessingD28,
        count(distinct case 
                        when order_status = 'processing' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 56 
                        then p.order_id end) as qtdPedidosProcessingD56,
        count(distinct case 
                        when order_status = 'processing' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 365 
                        then p.order_id end) as qtdPedidosProcessingD365,
        count(distinct case 
                        when order_status = 'unavailable' 
                        then p.order_id end) as qtdPedidosUnavailableVida,
        count(distinct case 
                        when order_status = 'unavailable' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 28 
                        then p.order_id end) as qtdPedidosUnavailableD28,
        count(distinct case 
                        when order_status = 'unavailable' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 56 
                        then p.order_id end) as qtdPedidosUnavailableD56,
        count(distinct case 
                        when order_status = 'unavailable' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 365 
                        then p.order_id end) as qtdPedidosUnavailableD365,
        count(distinct case 
                        when order_status = 'canceled' 
                        then p.order_id end) as qtdPedidosCanceledVida,
        count(distinct case 
                        when order_status = 'canceled' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 28 
                        then p.order_id end) as qtdPedidosCanceledD28,
        count(distinct case 
                        when order_status = 'canceled' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 56 
                        then p.order_id end) as qtdPedidosCanceledD56,
        count(distinct case 
                        when order_status = 'canceled' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 365 
                        then p.order_id end) as qtdPedidosCanceledD365,
        count(distinct case 
                        when order_status = 'created' 
                        then p.order_id end) as qtdPedidosCreatedVida,
         count(distinct case 
                        when order_status = 'created' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 28 
                        then p.order_id end) as qtdPedidosCreatedD28,
        count(distinct case 
                        when order_status = 'created' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 56 
                        then p.order_id end) as qtdPedidosCreatedD56,
        count(distinct case 
                        when order_status = 'created' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 365 
                        then p.order_id end) as qtdPedidosCreatedD365,
        count(distinct case 
                        when order_status = 'approved' 
                        then p.order_id end) as qtdPedidosApprovedVida,
         count(distinct case 
                        when order_status = 'approved' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 28 
                        then p.order_id end) as qtdPedidosApprovedD28,
        count(distinct case 
                        when order_status = 'approved' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 56 
                        then p.order_id end) as qtdPedidosApprovedD56,
        count(distinct case 
                        when order_status = 'approved' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 365 
                        then p.order_id end) as qtdPedidosApprovedD365,
        count(i.product_id) as qtdItensVendaVida,
        count(case 
                when datediff(d.dt_referencia, p.order_purchase_timestamp) <= 28 
                then i.product_id end) as qtdItensVendaD28,
        count(case 
                when datediff(d.dt_referencia, p.order_purchase_timestamp) <= 56 
                then i.product_id end) as qtdItensVendaD56,
        count(case 
                when datediff(d.dt_referencia, p.order_purchase_timestamp) <= 365 
                then i.product_id end) as qtdItensVendaD365,
        min(date_diff(d.dt_referencia, p.order_purchase_timestamp)) as diasDesdeUltimaVenda,
        max(date_diff(d.dt_referencia, p.order_purchase_timestamp)) as diasDesdePrimeiraVenda       
                          
    from tb_pedidos p
    left join workspace.olist.order_items i on p.order_id = i.order_id
    left join workspace.olist.sellers s on i.seller_id = s.seller_id
    cross join tb_data d
    group by s.seller_id 
)
SELECT * FROM tb_seller_rfv