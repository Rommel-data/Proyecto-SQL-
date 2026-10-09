-- =====================================================================
-- 02_limpieza.sql · Proyecto SQL Tunki · Databricks SQL
-- Catálogo: bd_e_commerce_tunki · Esquema: default
--
-- 1. Detección   → 5 controles de calidad
-- 2. Limpieza    → tablas limpias (las originales no se modifican)
-- 3. Verificación → prueba de que la limpieza funcionó
-- 4. Reglas para el análisis → al final, como comentario
-- =====================================================================

USE CATALOG bd_e_commerce_tunki;
USE SCHEMA default;
 

-- =====================================================================
-- 1. DETECCIÓN
-- =====================================================================
 
-- 1.1 Valores nulos (se revisaron las 4 tablas; solo customers.city tiene nulos)
SELECT
  COUNT(*)                               AS filas,
  count_if(customer_id IS NULL)          AS nulos_customer_id,
  count_if(signup_date IS NULL)          AS nulos_signup_date,
  count_if(shipping_region IS NULL)      AS nulos_shipping_region,
  count_if(city IS NULL)                 AS nulos_city,
  count_if(acquisition_channel IS NULL)  AS nulos_channel
FROM customers;
-- Resultado: 435 clientes sin city
 
-- 1.2 Duplicados (se revisó la llave de las 4 tablas; solo orders tiene duplicados)
SELECT
  COUNT(*)                  AS filas_totales,
  COUNT(DISTINCT order_id)  AS pedidos_unicos
FROM orders;
-- Resultado: 39.528 filas vs 39.331 pedidos → 197 duplicados
 
-- 1.3 Texto inconsistente (se revisaron todas las columnas de texto)
SELECT 
  DISTINCT shipping_region
FROM customers
ORDER BY shipping_region;
-- Resultado: 10 formas de escribir 2 regiones (mayúsculas y espacios)

-- 1.4 Rango de fechas
SELECT
  DATE(MIN(order_datetime))  AS primer_pedido,
  DATE(MAX(order_datetime))  AS ultimo_pedido
FROM orders;
 
SELECT
  date_format(order_datetime, 'yyyy-MM')  AS mes,
  COUNT(DISTINCT DATE(order_datetime))    AS dias_con_pedidos
FROM orders
GROUP BY 1
ORDER BY 1;
-- Resultado: 01-01-2024 al 12-02-2026; febrero 2026 solo tiene 12 días

-- 1.5 Consistencia entre tablas
 
-- a) ¿El monto del pedido cuadra con la suma de sus líneas?
WITH monto_por_pedido AS (
    SELECT 
        order_id, 
        SUM(quantity * unit_price) AS total_lineas
    FROM order_items
  GROUP BY order_id
)
SELECT 
  count_if(ABS(o.merchandise_value - mp.total_lineas) > 0.01) AS pedidos_que_no_cuadran
FROM orders o
JOIN monto_por_pedido mp ON mp.order_id = o.order_id;
-- Resultado: 0 → merchandise_value es confiable
 
-- b) ¿El precio y el costo de cada venta coinciden con el catálogo?
SELECT
  count_if(oi.unit_price <> p.unit_price)  AS precio_distinto,
  count_if(oi.unit_cost  <> p.unit_cost)   AS costo_distinto,
  COUNT(*)                                 AS lineas
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id;
-- Resultado: 49.674 de 74.821 líneas (66 %) con precio y costo distintos
 
-- b2) ¿Desde cuándo las ventas coinciden con el catálogo?
SELECT
  date_format(o.order_datetime, 'yyyy-MM')  AS mes,
  count_if(oi.unit_price <> p.unit_price)   AS lineas_precio_distinto,
  COUNT(*)                                  AS lineas
FROM order_items oi
JOIN products p      ON p.product_id = oi.product_id
JOIN orders_clean o  ON o.order_id   = oi.order_id
GROUP BY 1
ORDER BY 1;
-- Resultado: hasta jun-2025 el 100 % de las líneas difiere del catálogo; desde jul-2025, el 0 %.
-- Resultado: en jul-2025 cambió la lista → precios +4 %, costos +3 % (vs lista anterior).

-- c) ¿El nombre identifica al producto?
SELECT
  COUNT(*)                      AS productos,
  COUNT(DISTINCT product_name)  AS nombres_unicos
FROM products;
-- Resultado: 400 productos, 208 nombres → el nombre no es único
 

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

-- Debe dar 39.331 = 39.331
SELECT 
    COUNT(*) AS filas, 
    COUNT(DISTINCT order_id) AS pedidos_unicos
FROM orders_clean;

-- Debe dar solo 2 regiones: lima y provincia
SELECT 
    shipping_region, 
    COUNT(*) AS clientes
FROM customers_clean
GROUP BY shipping_region;


-- =====================================================================
-- 4. REGLAS PARA EL ANÁLISIS
-- =====================================================================
-- • Usar orders_clean y customers_clean; order_items y products tal cual.
-- • Ventas y costos desde order_items u orders, nunca desde el catálogo.
-- • Agrupar productos por product_id, no por product_name.
-- • Excluir febrero 2026 (incompleto) de comparaciones mensuales.
-- • Redondear solo el resultado final: ROUND(SUM(...), 2).
-- • En jul-2025 cambió la lista de precios: al comparar crecimiento entre 
-- años, separar el efecto de precio del efecto de volumen (pedidos y unidades).