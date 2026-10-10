-- =====================================================================
-- 03_analisis.sql · Proyecto SQL Tunki · Databricks SQL
-- Definición de venta: order_status = 'COMPLETED', medida con merchandise_value.
-- Período: hasta enero 2026 (febrero 2026 está incompleto).
-- =====================================================================
 
USE CATALOG bd_e_commerce_tunki;
USE SCHEMA default;
 
-- ---------------------------------------------------------------------
-- Pregunta 1: ¿Cómo evolucionan las ventas, los pedidos y el ticket promedio cada mes?
-- ---------------------------------------------------------------------
SELECT
    DATE_FORMAT(order_datetime, 'yyyy-MM')              AS fecha,
    COUNT(order_id)                                     AS pedidos,
    ROUND(SUM(merchandise_value), 2)                    AS ventas,
    ROUND(SUM(merchandise_value) / COUNT(order_id), 2)  AS ticket_promedio
FROM orders_clean
WHERE order_status = 'COMPLETED'
  AND order_datetime < '2026-02-01'
GROUP BY fecha
ORDER BY fecha;
 
-- ---------------------------------------------------------------------
-- Pregunta 2: ¿Qué porcentaje de pedidos se cancela o se devuelve cada año?
-- ---------------------------------------------------------------------
SELECT
    YEAR(order_datetime)                                                AS anio,
    COUNT(*)                                                            AS pedidos,
    ROUND(count_if(order_status = 'CANCELLED') * 100.0 / COUNT(*), 1)   AS pct_cancelados,
    ROUND(count_if(order_status = 'RETURNED')  * 100.0 / COUNT(*), 1)   AS pct_devueltos,
    ROUND(SUM(CASE WHEN order_status <> 'COMPLETED'
                   THEN merchandise_value ELSE 0 END), 2)               AS ventas_perdidas
FROM orders_clean
WHERE order_datetime < '2026-02-01'
GROUP BY anio
ORDER BY anio;
-- La fila 2026 corresponde solo a enero
 
-- ---------------------------------------------------------------------
-- Pregunta 3: ¿Qué categorías venden más y cuáles dejan más margen?
-- ---------------------------------------------------------------------
SELECT
    p.category                                                       AS categoria,
    ROUND(SUM(oi.quantity * oi.unit_price), 2)                       AS ventas,
    ROUND(SUM(oi.quantity * (oi.unit_price - oi.unit_cost)), 2)      AS margen_bruto,
    ROUND(SUM(oi.quantity * (oi.unit_price - oi.unit_cost))
          / SUM(oi.quantity * oi.unit_price) * 100, 1)               AS margen_pct
FROM order_items oi
JOIN products p     ON p.product_id = oi.product_id
JOIN orders_clean o ON o.order_id   = oi.order_id
WHERE o.order_status = 'COMPLETED'
  AND o.order_datetime < '2026-02-01'
GROUP BY p.category
ORDER BY ventas DESC;
 
-- ---------------------------------------------------------------------
-- Pregunta 4: ¿Cuáles son los 3 productos más vendidos de cada categoría?
-- ---------------------------------------------------------------------
WITH ventas_producto AS (
    SELECT
        p.category                          AS categoria,
        p.product_id,
        p.product_name,
        SUM(oi.quantity * oi.unit_price)    AS ventas
    FROM order_items oi
    JOIN products p     ON p.product_id = oi.product_id
    JOIN orders_clean o ON o.order_id   = oi.order_id
    WHERE o.order_status = 'COMPLETED'
      AND o.order_datetime < '2026-02-01'
    GROUP BY p.category, p.product_id, p.product_name
)
SELECT *
FROM (
    SELECT
        categoria, 
        product_id, 
        product_name,
        ROUND(ventas, 2)                                                 AS ventas,
        ROW_NUMBER() OVER (PARTITION BY categoria ORDER BY ventas DESC)  AS puesto
    FROM ventas_producto
) AS ranking
WHERE puesto <= 3
ORDER BY categoria, puesto;
 
-- ---------------------------------------------------------------------
-- Pregunta 5: ¿Cómo se comparan Lima y provincia en ventas, ticket y costo de envío?
-- ---------------------------------------------------------------------
SELECT
    c.shipping_region                                               AS region,
    COUNT(o.order_id)                                               AS pedidos,
    ROUND(SUM(o.merchandise_value), 2)                              AS ventas_total,
    ROUND(SUM(o.merchandise_value) / COUNT(o.order_id), 2)          AS ticket_promedio,
    ROUND(AVG(o.shipping_fee_charged), 2)                           AS envio_cobrado_prom,
    ROUND(AVG(o.shipping_cost_actual), 2)                           AS envio_costo_prom,
    ROUND(SUM(o.shipping_cost_actual - o.shipping_fee_charged), 2)  AS subsidio_envio_total
FROM orders_clean o
JOIN customers_clean c ON c.customer_id = o.customer_id
WHERE o.order_status = 'COMPLETED'
  AND o.order_datetime < '2026-01-01'
GROUP BY c.shipping_region
ORDER BY ventas_total DESC;
 
-- ---------------------------------------------------------------------
-- Pregunta 6: ¿Cómo crecen las ventas frente al mismo mes del año anterior?
-- ---------------------------------------------------------------------
WITH ventas_mes AS (
    SELECT
        DATE_TRUNC('MONTH', order_datetime)  AS mes,
        SUM(merchandise_value)               AS ventas
    FROM orders_clean
    WHERE order_status = 'COMPLETED'
      AND order_datetime < '2026-02-01'
    GROUP BY mes
),
comparado AS (
    SELECT
        mes, 
        ventas,
        LAG(ventas)  OVER (PARTITION BY MONTH(mes) ORDER BY mes)  AS ventas_aa
    FROM ventas_mes
)
SELECT
    DATE_FORMAT(mes, 'yyyy-MM')                          AS fecha,
    ROUND(ventas, 2)                                     AS ventas,
    ROUND(ventas_aa, 2)                                  AS ventas_anio_anterior,
    ROUND((ventas / ventas_aa - 1) * 100, 1)             AS crec_ventas_pct
FROM comparado
WHERE ventas_aa IS NOT NULL
ORDER BY mes;
 
-- ---------------------------------------------------------------------
-- Pregunta 7: ¿En qué región y en qué tipo de pedido cayó enero 2026?
-- ---------------------------------------------------------------------
SELECT
    c.shipping_region                                  AS region,
    CASE
        WHEN o.merchandise_value < 79  THEN '1. Menos de S/ 79'
        WHEN o.merchandise_value < 149 THEN '2. S/ 79 a 149'
        ELSE                                '3. S/ 149 a más'
    END                                                AS rango_monto,
    count_if(YEAR(o.order_datetime) = 2025)            AS pedidos_ene_2025,
    count_if(YEAR(o.order_datetime) = 2026)            AS pedidos_ene_2026
FROM orders_clean o
JOIN customers_clean c ON c.customer_id = o.customer_id
WHERE o.order_status = 'COMPLETED' AND MONTH(o.order_datetime) = 1 AND YEAR(o.order_datetime) IN (2025, 2026)
GROUP BY region, rango_monto
ORDER BY region, rango_monto;
 
-- ---------------------------------------------------------------------
-- Pregunta 8: ¿Qué cambió en el envío a provincia en enero 2026?
-- ---------------------------------------------------------------------
SELECT
    c.shipping_region                                                            AS region,
    CASE WHEN o.order_datetime < '2026-01-01' THEN '2024-2025' ELSE '2026' END   AS periodo,
    o.shipping_fee_charged                                                       AS envio_cobrado,
    COUNT(*)                                                                     AS pedidos,
    ROUND(MIN(o.merchandise_value), 2)                                           AS monto_min,
    ROUND(MAX(o.merchandise_value), 2)                                           AS monto_max
FROM orders_clean o
JOIN customers_clean c ON c.customer_id = o.customer_id
WHERE o.order_status = 'COMPLETED'
GROUP BY region, periodo, envio_cobrado
ORDER BY region, periodo, envio_cobrado;