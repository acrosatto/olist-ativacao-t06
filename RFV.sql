-- ============================================================
  -- Seller RFV + Métricas de Engajamento
  -- Data de referência: 2018-07-01
  -- Granularidade: 1 linha por seller
  -- ============================================================

  WITH params AS (
      SELECT DATE('{date}') AS dt_referencia
  )

  -- Base: sellers com ao menos um pedido antes da data de referência
  , tb_sellers AS (
      SELECT DISTINCT oi.seller_id
      FROM workspace.olist.orders o
      INNER JOIN workspace.olist.order_items oi
          ON o.order_id = oi.order_id
      CROSS JOIN params p
      WHERE o.order_purchase_timestamp < p.dt_referencia
  )

  -- ============================================================
  -- Intervalos entre vendas
  -- Métricas: média, mín, máx, P25, P50, P75 dos dias entre vendas
  -- ============================================================
  , tb_intervalo_vendas AS (
      WITH tb_ref AS (
          SELECT DATE(p.dt_referencia) AS dt_referencia
          FROM params p
      ),
      tb_pedidos AS (
          -- Filtra pedidos antes da data de referência
          SELECT o.*
          FROM workspace.olist.orders o
          CROSS JOIN tb_ref r
          WHERE o.order_purchase_timestamp < r.dt_referencia
      ),
      tb_vendas AS (
          -- Uma linha por seller + dia de venda (elimina duplicatas de itens no mesmo pedido)
          SELECT DISTINCT
                 oi.seller_id,
                 o.order_id,
                 DATE(o.order_purchase_timestamp) AS dtVenda
          FROM tb_pedidos o
          INNER JOIN workspace.olist.order_items oi ON o.order_id = oi.order_id
      ),
      tb_intervalos AS (
          -- Para cada venda, busca a data da venda anterior do mesmo seller com LAG
          SELECT
              seller_id,
              dtVenda,
              LAG(dtVenda) OVER (PARTITION BY seller_id ORDER BY dtVenda) AS
  dtVendaAnterior
          FROM tb_vendas
      ),
      tb_dias_entre_vendas AS (
          -- Calcula os dias entre cada venda e a anterior
          -- WHERE remove a primeira venda de cada seller (não tem anterior)
          SELECT
              seller_id,
              DATEDIFF(day, dtVendaAnterior, dtVenda) AS vlDiasEntreVendas
          FROM tb_intervalos
          WHERE dtVendaAnterior IS NOT NULL
      )
      -- Agrega estatísticas de intervalo por seller
      SELECT
          seller_id,
          AVG(vlDiasEntreVendas) AS vlDiasEntreVendasMedio,
          MIN(vlDiasEntreVendas) AS vlDiasEntreVendasMin,
          MAX(vlDiasEntreVendas) AS vlDiasEntreVendasMax,
          PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY vlDiasEntreVendas) AS
  vlDiasEntreVendasP25,
          PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY vlDiasEntreVendas) AS
  vlDiasEntreVendasP50,
          PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY vlDiasEntreVendas) AS
  vlDiasEntreVendasP75
      FROM tb_dias_entre_vendas
      GROUP BY seller_id
  )

  -- ============================================================
  -- Pedidos por status e janela temporal
  -- Métricas: contagem de pedidos por status nos períodos
  --           Vida, D28, D56, D365; itens vendidos; recência
  -- ============================================================
  , tb_pedidos_por_status AS (
      WITH tb_ref AS (
          SELECT DATE(p.dt_referencia) AS dt_referencia
          FROM params p
      ),
      tb_pedidos AS (
          -- Filtra pedidos antes da data de referência, incluindo dt_referencia para os cálculos
          SELECT o.*, r.dt_referencia
          FROM workspace.olist.orders o
          CROSS JOIN tb_ref r
          WHERE o.order_purchase_timestamp < r.dt_referencia
      ),
      tb_agg AS (
          SELECT
              i.seller_id,
              -- Pedidos totais por janela
              COUNT(DISTINCT p.order_id) AS qtdPedidosVida,
              COUNT(DISTINCT CASE WHEN datediff(p.dt_referencia,
  p.order_purchase_timestamp) <= 28  THEN p.order_id END) AS qtdPedidosD28,
              COUNT(DISTINCT CASE WHEN datediff(p.dt_referencia,
  p.order_purchase_timestamp) <= 56  THEN p.order_id END) AS qtdPedidosD56,
              COUNT(DISTINCT CASE WHEN datediff(p.dt_referencia,
  p.order_purchase_timestamp) <= 365 THEN p.order_id END) AS qtdPedidosD365,
              -- Delivered
              COUNT(DISTINCT CASE WHEN p.order_status = 'delivered' THEN p.order_id
  END) AS qtdPedidosDeliveredVida,
              COUNT(DISTINCT CASE WHEN p.order_status = 'delivered' AND
  datediff(p.dt_referencia, p.order_purchase_timestamp) <= 28  THEN p.order_id END)
  AS qtdPedidosDeliveredD28,
              COUNT(DISTINCT CASE WHEN p.order_status = 'delivered' AND
  datediff(p.dt_referencia, p.order_purchase_timestamp) <= 56  THEN p.order_id END)
  AS qtdPedidosDeliveredD56,
              COUNT(DISTINCT CASE WHEN p.order_status = 'delivered' AND
  datediff(p.dt_referencia, p.order_purchase_timestamp) <= 365 THEN p.order_id END)
  AS qtdPedidosDeliveredD365,
              -- Invoiced
              COUNT(DISTINCT CASE WHEN p.order_status = 'invoiced' THEN p.order_id
  END) AS qtdPedidosInvoicedVida,
              COUNT(DISTINCT CASE WHEN p.order_status = 'invoiced' AND
  datediff(p.dt_referencia, p.order_purchase_timestamp) <= 28  THEN p.order_id END)
  AS qtdPedidosInvoicedD28,
              COUNT(DISTINCT CASE WHEN p.order_status = 'invoiced' AND
  datediff(p.dt_referencia, p.order_purchase_timestamp) <= 56  THEN p.order_id END)
  AS qtdPedidosInvoicedD56,
              COUNT(DISTINCT CASE WHEN p.order_status = 'invoiced' AND
  datediff(p.dt_referencia, p.order_purchase_timestamp) <= 365 THEN p.order_id END)
  AS qtdPedidosInvoicedD365,
              -- Shipped
              COUNT(DISTINCT CASE WHEN p.order_status = 'shipped' THEN p.order_id
  END) AS qtdPedidosShippedVida,
              COUNT(DISTINCT CASE WHEN p.order_status = 'shipped' AND
  datediff(p.dt_referencia, p.order_purchase_timestamp) <= 28  THEN p.order_id END)
  AS qtdPedidosShippedD28,
              COUNT(DISTINCT CASE WHEN p.order_status = 'shipped' AND
  datediff(p.dt_referencia, p.order_purchase_timestamp) <= 56  THEN p.order_id END)
  AS qtdPedidosShippedD56,
              COUNT(DISTINCT CASE WHEN p.order_status = 'shipped' AND
  datediff(p.dt_referencia, p.order_purchase_timestamp) <= 365 THEN p.order_id END)
  AS qtdPedidosShippedD365,
              -- Processing
              COUNT(DISTINCT CASE WHEN p.order_status = 'processing' THEN
  p.order_id END) AS qtdPedidosProcessingVida,
              COUNT(DISTINCT CASE WHEN p.order_status = 'processing' AND
  datediff(p.dt_referencia, p.order_purchase_timestamp) <= 28  THEN p.order_id END)
  AS qtdPedidosProcessingD28,
              COUNT(DISTINCT CASE WHEN p.order_status = 'processing' AND
  datediff(p.dt_referencia, p.order_purchase_timestamp) <= 56  THEN p.order_id END)
  AS qtdPedidosProcessingD56,
              COUNT(DISTINCT CASE WHEN p.order_status = 'processing' AND
  datediff(p.dt_referencia, p.order_purchase_timestamp) <= 365 THEN p.order_id END)
  AS qtdPedidosProcessingD365,
              -- Unavailable
              COUNT(DISTINCT CASE WHEN p.order_status = 'unavailable' THEN
  p.order_id END) AS qtdPedidosUnavailableVida,
              COUNT(DISTINCT CASE WHEN p.order_status = 'unavailable' AND
  datediff(p.dt_referencia, p.order_purchase_timestamp) <= 28  THEN p.order_id END)
  AS qtdPedidosUnavailableD28,
              COUNT(DISTINCT CASE WHEN p.order_status = 'unavailable' AND
  datediff(p.dt_referencia, p.order_purchase_timestamp) <= 56  THEN p.order_id END)
  AS qtdPedidosUnavailableD56,
              COUNT(DISTINCT CASE WHEN p.order_status = 'unavailable' AND
  datediff(p.dt_referencia, p.order_purchase_timestamp) <= 365 THEN p.order_id END)
  AS qtdPedidosUnavailableD365,
              -- Canceled
              COUNT(DISTINCT CASE WHEN p.order_status = 'canceled' THEN p.order_id
  END) AS qtdPedidosCanceledVida,
              COUNT(DISTINCT CASE WHEN p.order_status = 'canceled' AND
  datediff(p.dt_referencia, p.order_purchase_timestamp) <= 28  THEN p.order_id END)
  AS qtdPedidosCanceledD28,
              COUNT(DISTINCT CASE WHEN p.order_status = 'canceled' AND
  datediff(p.dt_referencia, p.order_purchase_timestamp) <= 56  THEN p.order_id END)
  AS qtdPedidosCanceledD56,
              COUNT(DISTINCT CASE WHEN p.order_status = 'canceled' AND
  datediff(p.dt_referencia, p.order_purchase_timestamp) <= 365 THEN p.order_id END)
  AS qtdPedidosCanceledD365,
              -- Created
              COUNT(DISTINCT CASE WHEN p.order_status = 'created' THEN p.order_id
  END) AS qtdPedidosCreatedVida,
              COUNT(DISTINCT CASE WHEN p.order_status = 'created' AND
  datediff(p.dt_referencia, p.order_purchase_timestamp) <= 28  THEN p.order_id END)
  AS qtdPedidosCreatedD28,
              COUNT(DISTINCT CASE WHEN p.order_status = 'created' AND
  datediff(p.dt_referencia, p.order_purchase_timestamp) <= 56  THEN p.order_id END)
  AS qtdPedidosCreatedD56,
              COUNT(DISTINCT CASE WHEN p.order_status = 'created' AND
  datediff(p.dt_referencia, p.order_purchase_timestamp) <= 365 THEN p.order_id END)
  AS qtdPedidosCreatedD365,
              -- Approved
              COUNT(DISTINCT CASE WHEN p.order_status = 'approved' THEN p.order_id
  END) AS qtdPedidosApprovedVida,
              COUNT(DISTINCT CASE WHEN p.order_status = 'approved' AND
  datediff(p.dt_referencia, p.order_purchase_timestamp) <= 28  THEN p.order_id END)
  AS qtdPedidosApprovedD28,
              COUNT(DISTINCT CASE WHEN p.order_status = 'approved' AND
  datediff(p.dt_referencia, p.order_purchase_timestamp) <= 56  THEN p.order_id END)
  AS qtdPedidosApprovedD56,
              COUNT(DISTINCT CASE WHEN p.order_status = 'approved' AND
  datediff(p.dt_referencia, p.order_purchase_timestamp) <= 365 THEN p.order_id END)
  AS qtdPedidosApprovedD365,
              -- Itens vendidos por janela
              COUNT(i.product_id) AS qtdItensVendaVida,
              COUNT(CASE WHEN datediff(p.dt_referencia, p.order_purchase_timestamp)
  <= 28  THEN i.product_id END) AS qtdItensVendaD28,
              COUNT(CASE WHEN datediff(p.dt_referencia, p.order_purchase_timestamp)
  <= 56  THEN i.product_id END) AS qtdItensVendaD56,
              COUNT(CASE WHEN datediff(p.dt_referencia, p.order_purchase_timestamp)
  <= 365 THEN i.product_id END) AS qtdItensVendaD365,
              -- Recência
              MIN(datediff(p.dt_referencia, p.order_purchase_timestamp)) AS
  diasDesdeUltimaVenda,
              MAX(datediff(p.dt_referencia, p.order_purchase_timestamp)) AS
  diasDesdePrimeiraVenda
          FROM tb_pedidos p
          JOIN workspace.olist.order_items i ON p.order_id = i.order_id
          GROUP BY i.seller_id
      )
      SELECT * FROM tb_agg
  )

  -- ============================================================
  -- Dias de venda e engajamento
  -- Métricas: dias com venda por janela, dias sem venda,
  --           taxa de engajamento (dias com venda ÷ dias sem venda)
  -- ============================================================
  , tb_dias_vendas AS (
      WITH tb_ref AS (
          SELECT DATE(p.dt_referencia) AS dt_referencia
          FROM params p
      ),
      tb_agg AS (
          SELECT
              oi.seller_id,
              -- Total de dias distintos com ao menos uma venda
              COUNT(DISTINCT DATE(o.order_purchase_timestamp)) AS qtdDiasVendastotal,
              -- Dias com venda por janela temporal
              COUNT(DISTINCT CASE WHEN DATE(o.order_purchase_timestamp) >= DATE_SUB(r.dt_referencia, 28)
                  AND DATE(o.order_purchase_timestamp) <= r.dt_referencia
                  THEN DATE(o.order_purchase_timestamp) END) AS qtdDiasVendasD28,
              COUNT(DISTINCT CASE WHEN DATE(o.order_purchase_timestamp) >= DATE_SUB(r.dt_referencia, 56)
                  AND DATE(o.order_purchase_timestamp) <= r.dt_referencia
                  THEN DATE(o.order_purchase_timestamp) END) AS qtdDiasVendasD56,
              COUNT(DISTINCT CASE WHEN DATE(o.order_purchase_timestamp) >= DATE_SUB(r.dt_referencia, 365)
                  AND DATE(o.order_purchase_timestamp) <= r.dt_referencia
                  THEN DATE(o.order_purchase_timestamp) END) AS qtdDiasVendasD365,
              -- Dias sem venda = dias totais na base - dias com venda
              DATEDIFF(r.dt_referencia, MIN(DATE(o.order_purchase_timestamp))) -
              COUNT(DISTINCT DATE(o.order_purchase_timestamp)) AS qtdDiasSemVendas,
              -- Engajamento: dias com venda / dias sem venda
              -- TRY_DIVIDE evita divisão por zero (seller que nunca ficou sem vender)
              ROUND(COALESCE(TRY_DIVIDE(
                  COUNT(DISTINCT DATE(o.order_purchase_timestamp)),
                  DATEDIFF(r.dt_referencia, MIN(DATE(o.order_purchase_timestamp))) -
                  COUNT(DISTINCT DATE(o.order_purchase_timestamp))), 0), 2) AS txEngajamento
          FROM workspace.olist.orders o
          JOIN workspace.olist.order_items oi ON o.order_id = oi.order_id
          CROSS JOIN tb_ref r
          WHERE o.order_purchase_timestamp < r.dt_referencia
          GROUP BY oi.seller_id, r.dt_referencia
      )
      SELECT * FROM tb_agg
  )

  -- ============================================================
  -- Taxa de ativação por dia
  -- Métrica: dias distintos com venda ÷ dias totais na base
  --          nos períodos Vida, D28, D56, D365
  -- ============================================================
  , tb_ativacao_diaria AS (
      WITH tb_ref AS (
          SELECT DATE(p.dt_referencia) AS dt_referencia
          FROM params p
      )
      SELECT
          s.seller_id,
          -- Vida: dias com venda / dias desde primeira venda
          ROUND(COALESCE(TRY_DIVIDE(
              COUNT(DISTINCT DATE(o.order_purchase_timestamp)),
              DATEDIFF(r.dt_referencia, MIN(DATE(o.order_purchase_timestamp)))
          ), 0), 2) AS txAtivacaoPorDiaVida,
          -- D28: dias com venda nos últimos 28 dias / 28
          ROUND(COALESCE(TRY_DIVIDE(COUNT(DISTINCT CASE WHEN DATE(o.order_purchase_timestamp) >= DATE_SUB(r.dt_referencia, 28)
                  THEN DATE(o.order_purchase_timestamp) END), 28), 0), 2) AS txAtivacaoPorDiaD28,
          -- D56: dias com venda nos últimos 56 dias / 56
          ROUND(COALESCE(TRY_DIVIDE(COUNT(DISTINCT CASE WHEN DATE(o.order_purchase_timestamp) >= DATE_SUB(r.dt_referencia, 56)
                  THEN DATE(o.order_purchase_timestamp) END), 56), 0), 2) AS txAtivacaoPorDiaD56,
          -- D365: dias com venda nos últimos 365 dias / 365
          ROUND(COALESCE(TRY_DIVIDE(COUNT(DISTINCT CASE WHEN DATE(o.order_purchase_timestamp) >= DATE_SUB(r.dt_referencia, 365)
                  THEN DATE(o.order_purchase_timestamp) END), 365), 0), 2) AS txAtivacaoPorDiaD365
      FROM workspace.olist.sellers s
      CROSS JOIN tb_ref r
      LEFT JOIN workspace.olist.order_items i ON s.seller_id = i.seller_id
      LEFT JOIN workspace.olist.orders o      ON i.order_id  = o.order_id
      WHERE o.order_purchase_timestamp < r.dt_referencia
      GROUP BY s.seller_id, r.dt_referencia
  )

  -- ============================================================
  -- Receita e ticket médio por janela temporal
  -- Métricas: receita total e ticket médio nos períodos Vida, D28, D56, D365
  -- ============================================================
  , tb_receita AS (
      WITH tb_ref AS (
          SELECT DATE(p.dt_referencia) AS dt_referencia
          FROM params p
      ),
      tb_pedidos AS (
          -- Filtra pedidos antes da data de referência
          SELECT o.*
          FROM workspace.olist.orders o
          CROSS JOIN tb_ref r
          WHERE o.order_purchase_timestamp < r.dt_referencia
      ),
      tb_pedidos_seller AS (
          -- Agrega receita por pedido e seller (considera apenas o valor do produto)
          SELECT
              p.order_id,
              DATE(p.order_purchase_timestamp) AS dtPedido,
              i.seller_id,
              SUM(i.price) AS vlReceita
          FROM tb_pedidos p
          INNER JOIN workspace.olist.order_items i ON p.order_id = i.order_id
          GROUP BY 1, 2, 3
      ),
      tb_limites AS (
          -- Define os limites de cada janela temporal
          SELECT
              r.dt_referencia            AS dtLimite,
              DATE_SUB(r.dt_referencia, 28)  AS dtD28,
              DATE_SUB(r.dt_referencia, 56)  AS dtD56,
              DATE_SUB(r.dt_referencia, 365) AS dtD365
          FROM tb_ref r
      ),
      tb_agg AS (
          SELECT
              ps.seller_id,
              -- Receita por janela
              SUM(CASE WHEN ps.dtPedido BETWEEN l.dtD28  AND l.dtLimite THEN ps.vlReceita ELSE 0 END) AS vlReceitaD28,
              SUM(CASE WHEN ps.dtPedido BETWEEN l.dtD56  AND l.dtLimite THEN ps.vlReceita ELSE 0 END) AS vlReceitaD56,
              SUM(CASE WHEN ps.dtPedido BETWEEN l.dtD365 AND l.dtLimite THEN ps.vlReceita ELSE 0 END) AS vlReceitaD365,
              SUM(ps.vlReceita) AS vlReceitaVida,
              -- Ticket médio por janela (receita / nº de pedidos)
              SUM(CASE WHEN ps.dtPedido BETWEEN l.dtD28  AND l.dtLimite THEN ps.vlReceita ELSE 0 END) /
              NULLIF(COUNT(CASE WHEN ps.dtPedido BETWEEN l.dtD28  AND l.dtLimite 
              THEN ps.order_id END), 0) AS vlTicketMedioD28,
              SUM(CASE WHEN ps.dtPedido BETWEEN l.dtD56  AND l.dtLimite THEN ps.vlReceita ELSE 0 END) /
              NULLIF(COUNT(CASE WHEN ps.dtPedido BETWEEN l.dtD56  AND l.dtLimite
             THEN ps.order_id END), 0) AS vlTicketMedioD56,
              SUM(CASE WHEN ps.dtPedido BETWEEN l.dtD365 AND l.dtLimite THEN ps.vlReceita ELSE 0 END) /
              NULLIF(COUNT(CASE WHEN ps.dtPedido BETWEEN l.dtD365 AND l.dtLimite
              THEN ps.order_id END), 0) AS vlTicketMedioD365,
              SUM(ps.vlReceita) / NULLIF(COUNT(ps.order_id), 0) AS vlTicketMedioVida
          FROM tb_pedidos_seller ps
          CROSS JOIN tb_limites l
          GROUP BY ps.seller_id
      )
      SELECT * FROM tb_agg
  )

  -- ============================================================
  -- Consolidação final
  -- ============================================================
  SELECT
      s.*,
      iv.* EXCEPT (seller_id),
      ps.* EXCEPT (seller_id),
      -- Proporção de pedidos por janela em relação ao total histórico
      ROUND(ps.qtdPedidosD28  / NULLIF(ps.qtdPedidosVida, 0), 2) AS
  txPropPedidosD28,
      ROUND(ps.qtdPedidosD56  / NULLIF(ps.qtdPedidosVida, 0), 2) AS
  txPropPedidosD56,
      ROUND(ps.qtdPedidosD365 / NULLIF(ps.qtdPedidosVida, 0), 2) AS
  txPropPedidosD365,
      dv.* EXCEPT (seller_id),
      ad.* EXCEPT (seller_id),
      rc.* EXCEPT (seller_id)
  FROM tb_sellers s
  LEFT JOIN tb_intervalo_vendas   iv ON s.seller_id = iv.seller_id
  LEFT JOIN tb_pedidos_por_status ps ON s.seller_id = ps.seller_id
  LEFT JOIN tb_dias_vendas        dv ON s.seller_id = dv.seller_id
  LEFT JOIN tb_ativacao_diaria    ad ON s.seller_id = ad.seller_id
  LEFT JOIN tb_receita            rc ON s.seller_id = rc.seller_id
  ;
