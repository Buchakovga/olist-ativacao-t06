
WITH tb_pedidos AS (
  SELECT *
  FROM workspace.olist.orders
  WHERE order_purchase_timestamp < '2018-07-01'
),

tb_seller AS (
  SELECT
    order_id,
    seller_id
  FROM workspace.olist.order_items
  GROUP BY order_id, seller_id
),

tb_pagamentos AS (
  SELECT
    order_id,
    -- Valor por meio de pagamento
    SUM(CASE WHEN payment_type = 'credit_card'                                                    THEN payment_value ELSE 0 END) AS vlr_credit_card,
    SUM(CASE WHEN payment_type = 'boleto'                                                         THEN payment_value ELSE 0 END) AS vlr_boleto,
    SUM(CASE WHEN payment_type = 'voucher'                                                        THEN payment_value ELSE 0 END) AS vlr_voucher,
    SUM(CASE WHEN payment_type = 'debit_card'                                                     THEN payment_value ELSE 0 END) AS vlr_debit_card,
    SUM(CASE WHEN payment_type NOT IN ('credit_card', 'boleto', 'voucher', 'debit_card')          THEN payment_value ELSE 0 END) AS vlr_outros,
    -- Quantidade por meio de pagamento
    SUM(CASE WHEN payment_type = 'credit_card'                                                    THEN 1 ELSE 0 END) AS qtde_credit_card,
    SUM(CASE WHEN payment_type = 'boleto'                                                         THEN 1 ELSE 0 END) AS qtde_boleto,
    SUM(CASE WHEN payment_type = 'voucher'                                                        THEN 1 ELSE 0 END) AS qtde_voucher,
    SUM(CASE WHEN payment_type = 'debit_card'                                                     THEN 1 ELSE 0 END) AS qtde_debit_card,
    SUM(CASE WHEN payment_type NOT IN ('credit_card', 'boleto', 'voucher', 'debit_card')          THEN 1 ELSE 0 END) AS qtde_outros,
    -- Parcelamento
    MAX(CASE WHEN payment_installments > 0 THEN payment_installments END)                                            AS max_payment_installments
  FROM workspace.olist.order_payments
  GROUP BY order_id
),

tb_base AS (
  SELECT
    s.seller_id,
    p.order_purchase_timestamp,
    -- Valor
    pg.vlr_credit_card,
    pg.vlr_boleto,
    pg.vlr_voucher,
    pg.vlr_debit_card,
    pg.vlr_outros,
    -- Quantidade
    pg.qtde_credit_card,
    pg.qtde_boleto,
    pg.qtde_voucher,
    pg.qtde_debit_card,
    pg.qtde_outros,
    -- Parcelamento
    pg.max_payment_installments
  FROM tb_pedidos p
  INNER JOIN tb_seller     s  ON p.order_id = s.order_id
  LEFT  JOIN tb_pagamentos pg ON p.order_id = pg.order_id
),

tb_estrutura AS (
  SELECT DISTINCT
    seller_id,
    DATE_TRUNC('month', order_purchase_timestamp)                        AS ref_month,
    DATE_FORMAT(DATE_TRUNC('month', order_purchase_timestamp), 'yyyyMM') AS ref_month_fmt
  FROM tb_base
)

SELECT
  sp.seller_id,
  sp.ref_month_fmt AS ref_month,

  -- -------------------------------------------------------
  -- Valor médio por meio de pagamento
  -- -------------------------------------------------------
  -- D28
  AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 28)  THEN b.vlr_credit_card END) AS avg_vlr_credit_card_d28,
  AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 28)  THEN b.vlr_boleto      END) AS avg_vlr_boleto_d28,
  AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 28)  THEN b.vlr_voucher     END) AS avg_vlr_voucher_d28,
  AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 28)  THEN b.vlr_debit_card  END) AS avg_vlr_debit_card_d28,
  AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 28)  THEN b.vlr_outros      END) AS avg_vlr_outros_d28,
  -- D56
  AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 56)  THEN b.vlr_credit_card END) AS avg_vlr_credit_card_d56,
  AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 56)  THEN b.vlr_boleto      END) AS avg_vlr_boleto_d56,
  AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 56)  THEN b.vlr_voucher     END) AS avg_vlr_voucher_d56,
  AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 56)  THEN b.vlr_debit_card  END) AS avg_vlr_debit_card_d56,
  AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 56)  THEN b.vlr_outros      END) AS avg_vlr_outros_d56,
  -- D365
  AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 365) THEN b.vlr_credit_card END) AS avg_vlr_credit_card_d365,
  AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 365) THEN b.vlr_boleto      END) AS avg_vlr_boleto_d365,
  AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 365) THEN b.vlr_voucher     END) AS avg_vlr_voucher_d365,
  AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 365) THEN b.vlr_debit_card  END) AS avg_vlr_debit_card_d365,
  AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 365) THEN b.vlr_outros      END) AS avg_vlr_outros_d365,
  -- Vida
  AVG(b.vlr_credit_card) AS avg_vlr_credit_card_vida,
  AVG(b.vlr_boleto)      AS avg_vlr_boleto_vida,
  AVG(b.vlr_voucher)     AS avg_vlr_voucher_vida,
  AVG(b.vlr_debit_card)  AS avg_vlr_debit_card_vida,
  AVG(b.vlr_outros)      AS avg_vlr_outros_vida,

  -- -------------------------------------------------------
  -- Parcelamento médio
  -- -------------------------------------------------------
  AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 28)  THEN b.max_payment_installments END) AS avg_payment_installments_d28,
  AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 56)  THEN b.max_payment_installments END) AS avg_payment_installments_d56,
  AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 365) THEN b.max_payment_installments END) AS avg_payment_installments_d365,
  AVG(b.max_payment_installments)                                                                               AS avg_payment_installments_vida,

  -- -------------------------------------------------------
  -- Share de quantidade por meio de pagamento
  -- -------------------------------------------------------
  -- D28
  SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 28) THEN b.qtde_credit_card END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 28) THEN b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros END), 0) AS share_qtde_credit_card_d28,
  SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 28) THEN b.qtde_boleto      END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 28) THEN b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros END), 0) AS share_qtde_boleto_d28,
  SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 28) THEN b.qtde_voucher     END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 28) THEN b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros END), 0) AS share_qtde_voucher_d28,
  SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 28) THEN b.qtde_debit_card  END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 28) THEN b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros END), 0) AS share_qtde_debit_card_d28,
  SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 28) THEN b.qtde_outros      END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 28) THEN b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros END), 0) AS share_qtde_outros_d28,
  -- D56
  SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 56) THEN b.qtde_credit_card END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 56) THEN b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros END), 0) AS share_qtde_credit_card_d56,
  SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 56) THEN b.qtde_boleto      END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 56) THEN b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros END), 0) AS share_qtde_boleto_d56,
  SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 56) THEN b.qtde_voucher     END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 56) THEN b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros END), 0) AS share_qtde_voucher_d56,
  SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 56) THEN b.qtde_debit_card  END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 56) THEN b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros END), 0) AS share_qtde_debit_card_d56,
  SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 56) THEN b.qtde_outros      END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 56) THEN b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros END), 0) AS share_qtde_outros_d56,
  -- D365
  SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 365) THEN b.qtde_credit_card END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 365) THEN b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros END), 0) AS share_qtde_credit_card_d365,
  SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 365) THEN b.qtde_boleto      END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 365) THEN b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros END), 0) AS share_qtde_boleto_d365,
  SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 365) THEN b.qtde_voucher     END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 365) THEN b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros END), 0) AS share_qtde_voucher_d365,
  SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 365) THEN b.qtde_debit_card  END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 365) THEN b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros END), 0) AS share_qtde_debit_card_d365,
  SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 365) THEN b.qtde_outros      END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 365) THEN b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros END), 0) AS share_qtde_outros_d365,
  -- Vida
  SUM(b.qtde_credit_card) / NULLIF(SUM(b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros), 0) AS share_qtde_credit_card_vida,
  SUM(b.qtde_boleto)      / NULLIF(SUM(b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros), 0) AS share_qtde_boleto_vida,
  SUM(b.qtde_voucher)     / NULLIF(SUM(b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros), 0) AS share_qtde_voucher_vida,
  SUM(b.qtde_debit_card)  / NULLIF(SUM(b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros), 0) AS share_qtde_debit_card_vida,
  SUM(b.qtde_outros)      / NULLIF(SUM(b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros), 0) AS share_qtde_outros_vida,

  -- -------------------------------------------------------
  -- Share de valor por meio de pagamento
  -- -------------------------------------------------------
  -- D28
  SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 28) THEN b.vlr_credit_card END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 28) THEN b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros END), 0) AS share_valor_credit_card_d28,
  SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 28) THEN b.vlr_boleto      END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 28) THEN b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros END), 0) AS share_valor_boleto_d28,
  SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 28) THEN b.vlr_voucher     END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 28) THEN b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros END), 0) AS share_valor_voucher_d28,
  SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 28) THEN b.vlr_debit_card  END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 28) THEN b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros END), 0) AS share_valor_debit_card_d28,
  SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 28) THEN b.vlr_outros      END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 28) THEN b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros END), 0) AS share_valor_outros_d28,
  -- D56
  SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 56) THEN b.vlr_credit_card END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 56) THEN b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros END), 0) AS share_valor_credit_card_d56,
  SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 56) THEN b.vlr_boleto      END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 56) THEN b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros END), 0) AS share_valor_boleto_d56,
  SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 56) THEN b.vlr_voucher     END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 56) THEN b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros END), 0) AS share_valor_voucher_d56,
  SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 56) THEN b.vlr_debit_card  END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 56) THEN b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros END), 0) AS share_valor_debit_card_d56,
  SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 56) THEN b.vlr_outros      END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 56) THEN b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros END), 0) AS share_valor_outros_d56,
  -- D365
  SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 365) THEN b.vlr_credit_card END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 365) THEN b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros END), 0) AS share_valor_credit_card_d365,
  SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 365) THEN b.vlr_boleto      END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 365) THEN b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros END), 0) AS share_valor_boleto_d365,
  SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 365) THEN b.vlr_voucher     END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 365) THEN b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros END), 0) AS share_valor_voucher_d365,
  SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 365) THEN b.vlr_debit_card  END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 365) THEN b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros END), 0) AS share_valor_debit_card_d365,
  SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 365) THEN b.vlr_outros      END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB(sp.ref_month, 365) THEN b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros END), 0) AS share_valor_outros_d365,
  -- Vida
  SUM(b.vlr_credit_card) / NULLIF(SUM(b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros), 0) AS share_valor_credit_card_vida,
  SUM(b.vlr_boleto)      / NULLIF(SUM(b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros), 0) AS share_valor_boleto_vida,
  SUM(b.vlr_voucher)     / NULLIF(SUM(b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros), 0) AS share_valor_voucher_vida,
  SUM(b.vlr_debit_card)  / NULLIF(SUM(b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros), 0) AS share_valor_debit_card_vida,
  SUM(b.vlr_outros)      / NULLIF(SUM(b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros), 0) AS share_valor_outros_vida

FROM tb_estrutura sp
LEFT JOIN tb_base b
  ON  b.seller_id                  = sp.seller_id
  AND b.order_purchase_timestamp   < sp.ref_month

GROUP BY sp.seller_id, sp.ref_month, sp.ref_month_fmt
ORDER BY sp.seller_id, sp.ref_month
;
