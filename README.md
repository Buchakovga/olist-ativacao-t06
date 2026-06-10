# 📦 Feature Store — Olist
## `fs_seller_meio_pagamento`

> Documentação técnica da feature de meio de pagamento por seller.
> Parte da Feature Store do projeto Olist — Pós Graduação em Data Science Analytics, Turma T06, 2026.

---

## 📋 Índice

1. [Visão Geral](#1-visão-geral)
2. [Escopo do Projeto](#2-escopo-do-projeto)
3. [Tabela de Destino](#3-tabela-de-destino)
4. [Fontes de Dados](#4-fontes-de-dados)
5. [Lógica de Construção](#5-lógica-de-construção)
6. [Dicionário de Features](#6-dicionário-de-features)
7. [Exemplo de Uso](#7-exemplo-de-uso)
8. [Boas Práticas e Avisos](#8-boas-práticas-e-avisos)
9. [Histórico de Versões](#9-histórico-de-versões)

---

## 1. Visão Geral

A tabela `fs_seller_meio_pagamento` concentra métricas históricas de comportamento de pagamento por seller, calculadas em quatro janelas temporais (**D28, D56, D365 e vida toda**). Todas as features são construídas de forma retroativa ao mês de referência, garantindo ausência de *data leakage*.

As métricas cobrem quatro dimensões:

- **Valor médio** pago por meio de pagamento
- **Parcelamento médio** dos pedidos
- **Share de quantidade** de transações por meio de pagamento
- **Share de valor** transacionado por meio de pagamento

---

## 2. Escopo do Projeto

| Atributo   | Valor                                             |
|------------|---------------------------------------------------|
| Projeto    | Feature Store — Olist                             |
| Programa   | Pós Graduação em Data Science Analytics           |
| Turma      | T06 — 2026                                        |

### 👥 Equipe

| # | Nome              |
|---|-------------------|
| 1 | Anoel Azeredo     |
| 2 | Claudio Melo      |
| 3 | Felipe Rodrigo    |
| 4 | Juliana Souza     |
| 5 | Laynne Ribeiro    |
| 6 | Tiago Faustino    |

---

## 3. Tabela de Destino

| Atributo           | Valor                                                      |
|--------------------|------------------------------------------------------------|
| Catálogo           | `workspace.olist`                                          |
| Tabela             | `fs_seller_meio_pagamento`                                 |
| Granularidade      | `seller_id` × `ref_month`                                  |
| Período coberto    | Até 2018-06-01 (exclusive)                                 |
| Filtro de corte    | `order_purchase_timestamp < '2018-07-01'`                  |
| Atualização        | `INSERT OVERWRITE` completo                                |
| Total de colunas   | 66 (2 chaves + 64 features)                                |

---

## 4. Fontes de Dados

| Tabela fonte                        | Uso                                                              |
|-------------------------------------|------------------------------------------------------------------|
| `workspace.olist.orders`            | Base de pedidos — aplica o filtro de corte temporal              |
| `workspace.olist.order_items`       | Associa `order_id` ao `seller_id`                                |
| `workspace.olist.order_payments`    | Valores, tipos e parcelas de pagamento por pedido                |

---

## 5. Lógica de Construção

A query é estruturada em uma **única CTE** com cinco etapas antes do `SELECT` final:

```
orders  ──┐
           ├──► tb_pedidos ──┐
order_items ──► tb_seller ───┤
                              ├──► tb_base ──► tb_estrutura ──► SELECT final
order_payments ► tb_pagamentos ┘
```

| CTE             | Descrição                                                                                                          |
|-----------------|--------------------------------------------------------------------------------------------------------------------|
| `tb_pedidos`    | Filtra `orders` com `order_purchase_timestamp < '2018-07-01'`.                                                     |
| `tb_seller`     | Associa cada `order_id` ao `seller_id` via `order_items`.                                                          |
| `tb_pagamentos` | Agrega por `order_id`: valor e quantidade por tipo de pagamento + máximo de parcelas. **Leitura única da tabela.** |
| `tb_base`       | JOIN central pedidos × seller × pagamentos. Unidade: 1 linha por pedido × seller.                                 |
| `tb_estrutura`  | Grade de combinações `seller_id` × mês de referência (`DATE_TRUNC month`).                                        |
| `SELECT final`  | `LEFT JOIN tb_estrutura → tb_base` com filtro `< ref_month`. Calcula todas as métricas nas 4 janelas.              |

### 🕐 Janelas Temporais

| Sufixo   | Janela    | Descrição                                               |
|----------|-----------|---------------------------------------------------------|
| `_d28`   | 28 dias   | Últimos 28 dias anteriores ao mês de referência         |
| `_d56`   | 56 dias   | Últimos 56 dias anteriores ao mês de referência         |
| `_d365`  | 365 dias  | Últimos 365 dias anteriores ao mês de referência        |
| `_vida`  | Histórico | Todo o histórico disponível anterior ao mês de referência |

### 💳 Meios de Pagamento

| Código        | Descrição                             |
|---------------|---------------------------------------|
| `credit_card` | Cartão de crédito                     |
| `boleto`      | Boleto bancário                       |
| `voucher`     | Voucher                               |
| `debit_card`  | Cartão de débito                      |
| `outros`      | Qualquer tipo não listado acima       |

---

## 6. Dicionário de Features

### 🔑 Chaves

| Coluna       | Tipo     | Descrição                                                                                          |
|--------------|----------|----------------------------------------------------------------------------------------------------|
| `seller_id`  | STRING   | Identificador único do seller.                                                                     |
| `ref_month`  | STRING   | Mês de referência no formato `yyyyMM`. Todas as métricas consideram apenas informações anteriores a este mês. |

---

### 💰 Valor Médio por Meio de Pagamento (`avg_vlr_*`)

20 features — valor médio (R$) pago por tipo de pagamento em cada janela.

| Coluna                        | Tipo   | Descrição                                                                 |
|-------------------------------|--------|---------------------------------------------------------------------------|
| `avg_vlr_credit_card_d28`     | DOUBLE | Valor médio pago via cartão de crédito nos últimos 28 dias.               |
| `avg_vlr_boleto_d28`          | DOUBLE | Valor médio pago via boleto nos últimos 28 dias.                          |
| `avg_vlr_voucher_d28`         | DOUBLE | Valor médio pago via voucher nos últimos 28 dias.                         |
| `avg_vlr_debit_card_d28`      | DOUBLE | Valor médio pago via cartão de débito nos últimos 28 dias.                |
| `avg_vlr_outros_d28`          | DOUBLE | Valor médio pago por outros meios nos últimos 28 dias.                    |
| `avg_vlr_credit_card_d56`     | DOUBLE | Valor médio pago via cartão de crédito nos últimos 56 dias.               |
| `avg_vlr_boleto_d56`          | DOUBLE | Valor médio pago via boleto nos últimos 56 dias.                          |
| `avg_vlr_voucher_d56`         | DOUBLE | Valor médio pago via voucher nos últimos 56 dias.                         |
| `avg_vlr_debit_card_d56`      | DOUBLE | Valor médio pago via cartão de débito nos últimos 56 dias.                |
| `avg_vlr_outros_d56`          | DOUBLE | Valor médio pago por outros meios nos últimos 56 dias.                    |
| `avg_vlr_credit_card_d365`    | DOUBLE | Valor médio pago via cartão de crédito nos últimos 365 dias.              |
| `avg_vlr_boleto_d365`         | DOUBLE | Valor médio pago via boleto nos últimos 365 dias.                         |
| `avg_vlr_voucher_d365`        | DOUBLE | Valor médio pago via voucher nos últimos 365 dias.                        |
| `avg_vlr_debit_card_d365`     | DOUBLE | Valor médio pago via cartão de débito nos últimos 365 dias.               |
| `avg_vlr_outros_d365`         | DOUBLE | Valor médio pago por outros meios nos últimos 365 dias.                   |
| `avg_vlr_credit_card_vida`    | DOUBLE | Valor médio histórico pago via cartão de crédito.                         |
| `avg_vlr_boleto_vida`         | DOUBLE | Valor médio histórico pago via boleto.                                    |
| `avg_vlr_voucher_vida`        | DOUBLE | Valor médio histórico pago via voucher.                                   |
| `avg_vlr_debit_card_vida`     | DOUBLE | Valor médio histórico pago via cartão de débito.                          |
| `avg_vlr_outros_vida`         | DOUBLE | Valor médio histórico pago por outros meios.                              |

---

### 🔢 Parcelamento Médio (`avg_payment_installments_*`)

4 features — número médio de parcelas por janela.

| Coluna                              | Tipo   | Descrição                                                              |
|-------------------------------------|--------|------------------------------------------------------------------------|
| `avg_payment_installments_d28`      | DOUBLE | Quantidade média de parcelas dos pagamentos nos últimos 28 dias.       |
| `avg_payment_installments_d56`      | DOUBLE | Quantidade média de parcelas dos pagamentos nos últimos 56 dias.       |
| `avg_payment_installments_d365`     | DOUBLE | Quantidade média de parcelas dos pagamentos nos últimos 365 dias.      |
| `avg_payment_installments_vida`     | DOUBLE | Quantidade média histórica de parcelas dos pagamentos.                 |

> **Nota:** considera apenas registros com `payment_installments > 0`.

---

### 📊 Share de Quantidade por Meio de Pagamento (`share_qtde_*`)

20 features — participação percentual de cada meio na **quantidade** de transações.

| Coluna                           | Tipo   | Descrição                                                                        |
|----------------------------------|--------|----------------------------------------------------------------------------------|
| `share_qtde_credit_card_d28`     | DOUBLE | % de transações via cartão de crédito nos últimos 28 dias.                       |
| `share_qtde_boleto_d28`          | DOUBLE | % de transações via boleto nos últimos 28 dias.                                  |
| `share_qtde_voucher_d28`         | DOUBLE | % de transações via voucher nos últimos 28 dias.                                 |
| `share_qtde_debit_card_d28`      | DOUBLE | % de transações via cartão de débito nos últimos 28 dias.                        |
| `share_qtde_outros_d28`          | DOUBLE | % de transações via outros meios nos últimos 28 dias.                            |
| `share_qtde_credit_card_d56`     | DOUBLE | % de transações via cartão de crédito nos últimos 56 dias.                       |
| `share_qtde_boleto_d56`          | DOUBLE | % de transações via boleto nos últimos 56 dias.                                  |
| `share_qtde_voucher_d56`         | DOUBLE | % de transações via voucher nos últimos 56 dias.                                 |
| `share_qtde_debit_card_d56`      | DOUBLE | % de transações via cartão de débito nos últimos 56 dias.                        |
| `share_qtde_outros_d56`          | DOUBLE | % de transações via outros meios nos últimos 56 dias.                            |
| `share_qtde_credit_card_d365`    | DOUBLE | % de transações via cartão de crédito nos últimos 365 dias.                      |
| `share_qtde_boleto_d365`         | DOUBLE | % de transações via boleto nos últimos 365 dias.                                 |
| `share_qtde_voucher_d365`        | DOUBLE | % de transações via voucher nos últimos 365 dias.                                |
| `share_qtde_debit_card_d365`     | DOUBLE | % de transações via cartão de débito nos últimos 365 dias.                       |
| `share_qtde_outros_d365`         | DOUBLE | % de transações via outros meios nos últimos 365 dias.                           |
| `share_qtde_credit_card_vida`    | DOUBLE | % histórica de transações via cartão de crédito.                                 |
| `share_qtde_boleto_vida`         | DOUBLE | % histórica de transações via boleto.                                            |
| `share_qtde_voucher_vida`        | DOUBLE | % histórica de transações via voucher.                                           |
| `share_qtde_debit_card_vida`     | DOUBLE | % histórica de transações via cartão de débito.                                  |
| `share_qtde_outros_vida`         | DOUBLE | % histórica de transações via outros meios.                                      |

---

### 💵 Share de Valor por Meio de Pagamento (`share_valor_*`)

20 features — participação percentual de cada meio no **valor** total transacionado.

| Coluna                            | Tipo   | Descrição                                                                       |
|-----------------------------------|--------|---------------------------------------------------------------------------------|
| `share_valor_credit_card_d28`     | DOUBLE | % do valor pago via cartão de crédito nos últimos 28 dias.                      |
| `share_valor_boleto_d28`          | DOUBLE | % do valor pago via boleto nos últimos 28 dias.                                 |
| `share_valor_voucher_d28`         | DOUBLE | % do valor pago via voucher nos últimos 28 dias.                                |
| `share_valor_debit_card_d28`      | DOUBLE | % do valor pago via cartão de débito nos últimos 28 dias.                       |
| `share_valor_outros_d28`          | DOUBLE | % do valor pago via outros meios nos últimos 28 dias.                           |
| `share_valor_credit_card_d56`     | DOUBLE | % do valor pago via cartão de crédito nos últimos 56 dias.                      |
| `share_valor_boleto_d56`          | DOUBLE | % do valor pago via boleto nos últimos 56 dias.                                 |
| `share_valor_voucher_d56`         | DOUBLE | % do valor pago via voucher nos últimos 56 dias.                                |
| `share_valor_debit_card_d56`      | DOUBLE | % do valor pago via cartão de débito nos últimos 56 dias.                       |
| `share_valor_outros_d56`          | DOUBLE | % do valor pago via outros meios nos últimos 56 dias.                           |
| `share_valor_credit_card_d365`    | DOUBLE | % do valor pago via cartão de crédito nos últimos 365 dias.                     |
| `share_valor_boleto_d365`         | DOUBLE | % do valor pago via boleto nos últimos 365 dias.                                |
| `share_valor_voucher_d365`        | DOUBLE | % do valor pago via voucher nos últimos 365 dias.                               |
| `share_valor_debit_card_d365`     | DOUBLE | % do valor pago via cartão de débito nos últimos 365 dias.                      |
| `share_valor_outros_d365`         | DOUBLE | % do valor pago via outros meios nos últimos 365 dias.                          |
| `share_valor_credit_card_vida`    | DOUBLE | % histórica do valor pago via cartão de crédito.                                |
| `share_valor_boleto_vida`         | DOUBLE | % histórica do valor pago via boleto.                                           |
| `share_valor_voucher_vida`        | DOUBLE | % histórica do valor pago via voucher.                                          |
| `share_valor_debit_card_vida`     | DOUBLE | % histórica do valor pago via cartão de débito.                                 |
| `share_valor_outros_vida`         | DOUBLE | % histórica do valor pago via outros meios.                                     |

---

## 7. Exemplo de Uso

```sql
SELECT
  seller_id,
  ref_month,
  avg_vlr_credit_card_d28,
  avg_payment_installments_d28,
  share_qtde_credit_card_d28,
  share_valor_credit_card_d28
FROM workspace.olist.fs_seller_meio_pagamento
WHERE ref_month = '201806'
ORDER BY seller_id;
```

---

## 8. Boas Práticas e Avisos

> ⚠️ **Data Leakage:** o filtro `b.order_purchase_timestamp < sp.ref_month` garante que nenhuma informação futura ao mês de referência é utilizada no cálculo das features.

- **Divisão por zero:** o uso de `NULLIF` nos denominadores dos shares evita erros em sellers sem transações na janela.
- **Overwrite completo:** a tabela é recriada integralmente a cada execução — não há append incremental.
- **Alta variância em D28:** sellers com poucos pedidos podem apresentar médias instáveis na janela curta; considere filtros de volume mínimo no modelo downstream.
- **Parcelamento:** o campo `max_payment_installments` considera apenas registros com `payment_installments > 0`.
- **Performance:** a tabela `order_payments` é lida uma única vez na CTE `tb_pagamentos`, consolidando valor, quantidade e parcelamento em uma única passagem.

---

## 9. Histórico de Versões

| Versão | Data     | Autor      | Descrição                                                        |
|--------|----------|------------|------------------------------------------------------------------|
| 1.0    | Jun/2026 | Equipe T06 | Versão inicial — consolidação das 4 views originais em CTE única. |
