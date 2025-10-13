-- customer_churn_prediction_analysis.sql
-- Detect potentially churned customers based on inactivity

WITH customer_activity AS (
    SELECT
        c.customer_key,
        MAX(f.order_date) AS last_order_date,
        COUNT(DISTINCT f.order_number) AS total_orders,
        SUM(f.sales_amount) AS total_spent
    FROM gold.fact_sales f
    JOIN gold.dim_customers c
        ON f.customer_key = c.customer_key
    GROUP BY c.customer_key
),
days_since_last AS (
    SELECT
        customer_key,
        DATEDIFF(DAY, last_order_date, GETDATE()) AS days_inactive,
        total_orders,
        total_spent
    FROM customer_activity
)
SELECT
    customer_key,
    total_orders,
    total_spent,
    days_inactive,
    CASE 
        WHEN days_inactive > 180 THEN 'High Churn Risk'
        WHEN days_inactive BETWEEN 90 AND 180 THEN 'Medium Churn Risk'
        ELSE 'Active'
    END AS churn_status
FROM days_since_last
ORDER BY days_inactive DESC;
