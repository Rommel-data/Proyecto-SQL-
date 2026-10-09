-- =====================================================================
-- 01_DDL.sql · Proyecto SQL Tunki · Databricks SQL
-- Estructura de las 4 tablas del catálogo bd_e_commerce_tunki.default
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