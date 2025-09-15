-- Project 3: E‑Commerce Analysis — SQL Pack
-- Assumes a table: ecommerce_transactions
-- Columns: Transaction_ID (int), User_Name (text), Age (int), Country (text),
--          Product_Category (text), Purchase_Amount (numeric),
--          Payment_Method (text), Transaction_Date (date),
--          Order_Year (int), Order_Month (text 'YYYY-MM'), Order_Date (date)

/* -------------------------------------------------------------
   0) (Optional) Quick DDL you can use if creating a fresh table
   ------------------------------------------------------------- */
-- PostgreSQL
-- CREATE TABLE ecommerce_transactions (
--   Transaction_ID    BIGINT,
--   User_Name         TEXT,
--   Age               INT,
--   Country           TEXT,
--   Product_Category  TEXT,
--   Purchase_Amount   NUMERIC,
--   Payment_Method    TEXT,
--   Transaction_Date  DATE,
--   Order_Year        INT,
--   Order_Month       TEXT,  -- 'YYYY-MM'
--   Order_Date        DATE
-- );

-- SQLite/DuckDB tip to load the cleaned CSV (path may vary):
-- duckdb
--   CREATE TABLE ecommerce_transactions AS
--   SELECT * FROM read_csv_auto('../data/ecommerce_transactions_clean.csv');
-- sqlite
--   .mode csv
--   .import ../data/ecommerce_transactions_clean.csv ecommerce_transactions


/* -------------------------------------------------------------
   1) KPI Snapshot
   ------------------------------------------------------------- */
-- Total revenue, distinct transactions, distinct customers, AOV
SELECT
  SUM(Purchase_Amount)                     AS total_revenue,
  COUNT(DISTINCT Transaction_ID)           AS transactions,
  COUNT(DISTINCT User_Name)                AS unique_customers,
  AVG(Purchase_Amount)                     AS avg_order_value
FROM ecommerce_transactions;


/* -------------------------------------------------------------
   2) Monthly Revenue Trend
   ------------------------------------------------------------- */
-- If Order_Month exists ('YYYY-MM'), use it directly:
SELECT
  Order_Month,
  SUM(Purchase_Amount)              AS total_revenue,
  COUNT(*)                          AS transactions,
  COUNT(DISTINCT User_Name)         AS unique_customers,
  100.0 * (SUM(Purchase_Amount)
           - LAG(SUM(Purchase_Amount)) OVER (ORDER BY Order_Month))
           / NULLIF(LAG(SUM(Purchase_Amount)) OVER (ORDER BY Order_Month),0)
           AS revenue_mom_pct
FROM ecommerce_transactions
GROUP BY Order_Month
ORDER BY Order_Month;

-- If you DON'T have Order_Month, derive it from Transaction_Date (Postgres syntax):
-- SELECT
--   TO_CHAR(Transaction_Date, 'YYYY-MM')   AS order_month,
--   SUM(Purchase_Amount)                   AS total_revenue
-- FROM ecommerce_transactions
-- GROUP BY 1
-- ORDER BY 1;


/* -------------------------------------------------------------
   3) Top Product Categories
   ------------------------------------------------------------- */
SELECT
  Product_Category,
  SUM(Purchase_Amount)              AS total_revenue,
  COUNT(*)                          AS transactions,
  COUNT(DISTINCT User_Name)         AS unique_customers
FROM ecommerce_transactions
GROUP BY Product_Category
ORDER BY total_revenue DESC
LIMIT 10;


/* -------------------------------------------------------------
   4) Revenue by Country
   ------------------------------------------------------------- */
SELECT
  Country,
  SUM(Purchase_Amount)              AS total_revenue,
  COUNT(*)                          AS transactions,
  COUNT(DISTINCT User_Name)         AS unique_customers
FROM ecommerce_transactions
GROUP BY Country
ORDER BY total_revenue DESC
LIMIT 10;


/* -------------------------------------------------------------
   5) Top Customers by Spend
   ------------------------------------------------------------- */
SELECT
  User_Name,
  SUM(Purchase_Amount)              AS total_spent,
  COUNT(*)                          AS transactions
FROM ecommerce_transactions
GROUP BY User_Name
ORDER BY total_spent DESC
LIMIT 10;


/* -------------------------------------------------------------
   6) Repeat vs One‑Time Customers
   ------------------------------------------------------------- */
WITH counts AS (
  SELECT User_Name, COUNT(*) AS orders
  FROM ecommerce_transactions
  GROUP BY User_Name
)
SELECT
  CASE WHEN orders > 1 THEN 'Repeat' ELSE 'One-Time' END AS customer_type,
  COUNT(*)                                                AS customers,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)      AS pct_of_customers
FROM counts
GROUP BY 1
ORDER BY 2 DESC;


/* -------------------------------------------------------------
   7) Revenue by Payment Method
   ------------------------------------------------------------- */
SELECT
  Payment_Method,
  SUM(Purchase_Amount)              AS total_revenue,
  COUNT(*)                          AS transactions
FROM ecommerce_transactions
GROUP BY Payment_Method
ORDER BY total_revenue DESC;


/* -------------------------------------------------------------
   8) (Optional) Monthly x Category matrix
   ------------------------------------------------------------- */
SELECT
  Order_Month,
  Product_Category,
  SUM(Purchase_Amount) AS total_revenue
FROM ecommerce_transactions
GROUP BY Order_Month, Product_Category
ORDER BY Order_Month, total_revenue DESC;


/* -------------------------------------------------------------
   9) (Optional) Customer Recency / Frequency sketch
   ------------------------------------------------------------- */
-- Postgres example computing last order and frequency
-- SELECT
--   User_Name,
--   MAX(Transaction_Date)                       AS last_order_date,
--   COUNT(*)                                    AS order_count,
--   SUM(Purchase_Amount)                        AS total_spent
-- FROM ecommerce_transactions
-- GROUP BY User_Name
-- ORDER BY total_spent DESC;
