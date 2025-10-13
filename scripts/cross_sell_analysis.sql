-- cross_sell_opportunity_analysis
-- Find product pairs frequently purchased together

WITH order_products AS (
    SELECT DISTINCT order_number, product_key
    FROM gold.fact_sales
),
pair_combinations AS (
    SELECT 
        a.product_key AS product_a,
        b.product_key AS product_b
    FROM order_products a
    JOIN order_products b
        ON a.order_number = b.order_number
       AND a.product_key < b.product_key
),
pair_stats AS (
    SELECT
        pa.product_a,
        pb.product_name AS product_a_name,
        pa.product_b,
        pb2.product_name AS product_b_name,
        COUNT(*) AS times_bought_together
    FROM pair_combinations pa
    JOIN gold.dim_products pb ON pa.product_a = pb.product_key
    JOIN gold.dim_products pb2 ON pa.product_b = pb2.product_key
    GROUP BY pa.product_a, pb.product_name, pa.product_b, pb2.product_name
)
SELECT TOP 10 *
FROM pair_stats
ORDER BY times_bought_together DESC;
