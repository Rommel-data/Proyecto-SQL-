-- =====================================================================
-- 02_limpieza.sql · Proyecto SQL Tunki · Databricks SQL
-- Catálogo: bd_e_commerce_tunki · Esquema: default
--
-- Entrada : las 4 tablas cargadas desde los CSV (ver 01_DDL.sql)
-- Salida  : orders_clean, customers_clean y las reglas para el análisis
--
-- 1. Detección     → controles 1 a 4, sobre las tablas crudas
-- 2. Limpieza      → tablas limpias; las crudas no se modifican
-- 3. Verificación  → prueba de que la limpieza funcionó (incluye el control 5)
-- 4. Reglas para el análisis
-- =====================================================================

USE CATALOG bd_e_commerce_tunki;
USE SCHEMA default;


-- =====================================================================
-- 1. DETECCIÓN
-- =====================================================================

-- ---------------------------------------------------------------------
-- Control 1 · Valores nulos (todas las columnas de las 4 tablas)
-- ---------------------------------------------------------------------
SELECT
  COUNT(*)                               AS filas,
  count_if(customer_id IS NULL)          AS nulos_customer_id,
  count_if(signup_date IS NULL)          AS nulos_signup_date,
  count_if(shipping_region IS NULL)      AS nulos_shipping_region,
  count_if(city IS NULL)                 AS nulos_city,
  count_if(acquisition_channel IS NULL)  AS nulos_channel
FROM customers;
-- Resultado: 435 clientes sin city. El resto de columnas, sin nulos.

SELECT
  COUNT(*)                                AS filas,
  count_if(order_id IS NULL)              AS nulos_order_id,
  count_if(customer_id IS NULL)           AS nulos_customer_id,
  count_if(order_datetime IS NULL)        AS nulos_order_datetime,
  count_if(order_status IS NULL)          AS nulos_order_status,
  count_if(items_count IS NULL)           AS nulos_items_count,
  count_if(merchandise_value IS NULL)     AS nulos_merchandise_value,
  count_if(product_cost IS NULL)          AS nulos_product_cost,
  count_if(shipping_fee_charged IS NULL)  AS nulos_shipping_fee_charged,
  count_if(shipping_cost_actual IS NULL)  AS nulos_shipping_cost_actual,
  count_if(payment_fee IS NULL)           AS nulos_payment_fee
FROM orders;
-- Resultado: 0 nulos

SELECT
  COUNT(*)                         AS filas,
  count_if(order_item_id IS NULL)  AS nulos_order_item_id,
  count_if(order_id IS NULL)       AS nulos_order_id,
  count_if(product_id IS NULL)     AS nulos_product_id,
  count_if(quantity IS NULL)       AS nulos_quantity,
  count_if(unit_price IS NULL)     AS nulos_unit_price,
  count_if(unit_cost IS NULL)      AS nulos_unit_cost
FROM order_items;
-- Resultado: 0 nulos

SELECT
  COUNT(*)                        AS filas,
  count_if(product_id IS NULL)    AS nulos_product_id,
  count_if(product_name IS NULL)  AS nulos_product_name,
  count_if(category IS NULL)      AS nulos_category,
  count_if(unit_price IS NULL)    AS nulos_unit_price,
  count_if(unit_cost IS NULL)     AS nulos_unit_cost
FROM products;
-- Resultado: 0 nulos

-- ---------------------------------------------------------------------
-- Control 2 · Duplicados
-- ---------------------------------------------------------------------
-- a) ¿Cada llave aparece una sola vez?
SELECT 'customers' AS tabla, 
        COUNT(*) AS filas, 
        COUNT(DISTINCT customer_id) AS llaves_unicas 
FROM customers
UNION ALL
SELECT 'orders',               
        COUNT(*),          
        COUNT(DISTINCT order_id)                       
FROM orders
UNION ALL
SELECT 'order_items',          
        COUNT(*),          
        COUNT(DISTINCT order_item_id)                  
FROM order_items
UNION ALL
SELECT 'products',             
        COUNT(*),          
        COUNT(DISTINCT product_id)                     
FROM products;
-- Resultado: solo orders tiene duplicados → 39.528 filas vs 39.331 pedidos (197 de más)

-- b) ¿Los duplicados son copias exactas o el mismo pedido con datos distintos?
SELECT
  COUNT(*) AS filas_unicas
FROM (SELECT DISTINCT * FROM orders);
-- Resultado: 39.331 = pedidos únicos → son copias exactas, fila por fila.
-- Por eso alcanza con SELECT DISTINCT *. Si fueran versiones distintas del
-- mismo pedido, habría que decidir cuál conservar.

-- ---------------------------------------------------------------------
-- Control 3 · Texto inconsistente (columnas de texto que agrupan)
-- ---------------------------------------------------------------------
SELECT 'shipping_region' AS columna, 
        COUNT(DISTINCT shipping_region) AS valores_distintos 
FROM customers
UNION ALL
SELECT 'city',                           
        COUNT(DISTINCT city)                                     
FROM customers
UNION ALL
SELECT 'acquisition_channel',            
        COUNT(DISTINCT acquisition_channel)                      
FROM customers
UNION ALL
SELECT 'order_status',                   
        COUNT(DISTINCT order_status)                             
FROM orders
UNION ALL
SELECT 'category',                       
        COUNT(DISTINCT category)                                 
FROM products;
-- Resultado: 10 · 15 · 3 · 3 · 7. Solo shipping_region sobra: debería tener 2.

SELECT
  DISTINCT shipping_region
FROM customers
ORDER BY shipping_region;
-- Resultado: 10 formas de escribir 2 regiones (mayúsculas y espacios)

-- ---------------------------------------------------------------------
-- Control 4 · Rango de fechas
-- ---------------------------------------------------------------------
SELECT
  DATE(MIN(order_datetime))  AS primer_pedido,
  DATE(MAX(order_datetime))  AS ultimo_pedido
FROM orders;
-- Resultado: 01-01-2024 al 12-02-2026

SELECT
  date_format(order_datetime, 'yyyy-MM')  AS mes,
  COUNT(DISTINCT DATE(order_datetime))    AS dias_con_pedidos
FROM orders
GROUP BY mes
ORDER BY mes;
-- Resultado: todos los meses completos, salvo febrero 2026 (12 días)


-- =====================================================================
-- 2. LIMPIEZA
-- =====================================================================

-- Pedidos sin duplicados
CREATE OR REPLACE TABLE orders_clean AS
SELECT
  DISTINCT *
FROM orders;

-- Clientes con región estandarizada y ciudad sin nulos
CREATE OR REPLACE TABLE customers_clean AS
SELECT
  customer_id,
  signup_date,
  LOWER(TRIM(shipping_region))  AS shipping_region,
  COALESCE(city, 'Sin dato')    AS city,
  acquisition_channel
FROM customers;


-- =====================================================================
-- 3. VERIFICACIÓN
-- =====================================================================

-- a) Duplicados · un pedido por fila
SELECT
  COUNT(*)                  AS filas,
  COUNT(DISTINCT order_id)  AS pedidos_unicos
FROM orders_clean;
-- Resultado: 39.331 = 39.331
 
-- b) Texto inconsistente · dos regiones, sin perder clientes
SELECT
  shipping_region,
  COUNT(*) AS clientes
FROM customers_clean
GROUP BY shipping_region;
-- Resultado: lima 12.699 + provincia 9.783 = 22.482, el mismo total original
 
-- c) Valores nulos · ninguna ciudad nula
SELECT
  count_if(city IS NULL)        AS nulos_city,
  count_if(city = 'Sin dato')   AS sin_dato
FROM customers_clean;
-- Resultado: 0 nulos · 435 "Sin dato"
 
-- d) Duplicados · al quitarlos, la plata cuadra con el detalle
SELECT
  (SELECT ROUND(SUM(merchandise_value), 2)     FROM orders)        AS monto_orders_crudo,
  (SELECT ROUND(SUM(merchandise_value), 2)     FROM orders_clean)  AS monto_orders_limpio,
  (SELECT ROUND(SUM(quantity * unit_price), 2) FROM order_items)   AS monto_lineas;
-- Resultado: 6.057.474,50 · 6.027.715,59 · 6.027.715,59
-- Los 29.758,91 de diferencia eran plata contada dos veces por los duplicados.
 
-- e) Monto confiable · ¿el monto de cada pedido cuadra con la suma de sus líneas?
WITH monto_por_pedido AS (
  SELECT
    order_id,
    SUM(quantity * unit_price) AS total_lineas
  FROM order_items
  GROUP BY order_id
)
SELECT
  count_if(ABS(o.merchandise_value - mp.total_lineas) > 0.01) AS pedidos_que_no_cuadran
FROM orders_clean o
JOIN monto_por_pedido mp ON mp.order_id = o.order_id;
-- Resultado: 0 → merchandise_value es confiable, pedido por pedido
 
 
-- =====================================================================
-- 4. REGLAS PARA EL ANÁLISIS
-- =====================================================================
-- • Usar orders_clean y customers_clean; order_items y products tal cual.
-- • Para comparar regiones, usar shipping_region (city tiene "Sin dato").
-- • Excluir febrero 2026 (12 días) de las comparaciones mensuales.
-- • Redondear solo el resultado final: ROUND(SUM(...), 2), nunca antes de sumar.