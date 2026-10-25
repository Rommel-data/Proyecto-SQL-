-- =====================================================================
-- 01_DDL.sql · Proyecto SQL Tunki · Databricks SQL
-- Estructura de las 4 tablas del catálogo bd_e_commerce_tunki.default
--
-- Cómo entraron los datos: los 4 CSV de Data/ se subieron con la carga de
-- archivos de Databricks, que crea cada tabla e infiere sus tipos. Por eso
-- no hay INSERT INTO: las filas vienen en el archivo.
--
-- Para qué sirve este DDL: documenta el nombre y el tipo de cada columna,
-- y permite recrear la estructura en otro motor.
--
-- ⚠ No ejecutar sobre las tablas ya cargadas: CREATE OR REPLACE las
--   reemplaza por tablas vacías y se pierden las filas.
-- =====================================================================

USE CATALOG bd_e_commerce_tunki;
USE SCHEMA default;

-- Catálogo de productos
CREATE OR REPLACE TABLE products (
  product_id    STRING,
  product_name  STRING,
  category      STRING,
  unit_price    DOUBLE,
  unit_cost     DOUBLE
);

-- Clientes registrados
CREATE OR REPLACE TABLE customers (
  customer_id          STRING,
  signup_date          DATE,
  shipping_region      STRING,
  city                 STRING,
  acquisition_channel  STRING
);

-- Pedidos (cabecera)
CREATE OR REPLACE TABLE orders (
  order_id              STRING,
  customer_id           STRING,
  order_datetime        TIMESTAMP,
  order_status          STRING,
  items_count           LONG,
  merchandise_value     DOUBLE,
  product_cost          DOUBLE,
  shipping_fee_charged  DOUBLE,
  shipping_cost_actual  DOUBLE,
  payment_fee           DOUBLE
);

-- Detalle de pedidos
CREATE OR REPLACE TABLE order_items (
  order_item_id  STRING,
  order_id       STRING,
  product_id     STRING,
  quantity       LONG,
  unit_price     DOUBLE,
  unit_cost      DOUBLE
);


-- =====================================================================
-- CONTROL DE CARGA · ¿Llegó todo el CSV a Databricks?
-- =====================================================================

-- a) Mismas filas que el CSV
SELECT 'customers'   AS tabla, 
        COUNT(*) AS filas, 
        22482 AS filas_csv 
FROM customers
UNION ALL
SELECT 'orders',               
        COUNT(*),          
        39528              
FROM orders
UNION ALL
SELECT 'order_items',          
        COUNT(*),          
        74821              
FROM order_items
UNION ALL
SELECT 'products',             
        COUNT(*),           
        400                 
FROM products;
-- Resultado: las 4 tablas coinciden con su CSV

-- b) Tipos inferidos por Databricks (deben coincidir con el DDL de arriba)
DESCRIBE TABLE orders;
-- Esperado: order_datetime timestamp · items_count bigint (= LONG) · montos double