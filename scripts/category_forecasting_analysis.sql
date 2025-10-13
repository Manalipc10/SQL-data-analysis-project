-- category_forecasting_analysis
-- Forecast next month's revenue per category using linear regression

WITH monthly_sales AS (
    SELECT
        p.category,
        DATEFROMPARTS(YEAR(f.order_date), MONTH(f.order_date), 1) AS month_start,
        SUM(f.sales_amount) AS total_revenue
    FROM gold.fact_sales f
    JOIN gold.dim_products p ON f.product_key = p.product_key
    GROUP BY p.category, DATEFROMPARTS(YEAR(f.order_date), MONTH(f.order_date), 1)
),
indexed AS (
    SELECT
        category,
        month_start,
        total_revenue,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY month_start) AS month_index
    FROM monthly_sales
),
regression AS (
    SELECT
        category,
        COUNT(*) AS n,
        SUM(month_index) AS sum_x,
        SUM(total_revenue) AS sum_y,
        SUM(month_index * total_revenue) AS sum_xy,
        SUM(month_index * month_index) AS sum_x2
    FROM indexed
    GROUP BY category
),
coefficients AS (
    SELECT
        category,
        CAST((n * sum_xy - sum_x * sum_y) AS FLOAT) /
        NULLIF((n * sum_x2 - sum_x * sum_x), 0) AS slope,
        CAST((sum_y - ((n * sum_xy - sum_x * sum_y) /
             NULLIF((n * sum_x2 - sum_x * sum_x), 0)) * sum_x) AS FLOAT) / n AS intercept
    FROM regression
),
latest AS (
    SELECT
        category,
        MAX(month_start) AS last_month,
        MAX(month_index) + 1 AS next_month_index
    FROM indexed
    GROUP BY category
)
SELECT 
    l.category,
    l.last_month,
    DATEADD(MONTH, 1, l.last_month) AS forecast_month,
    CAST(c.intercept + c.slope * l.next_month_index AS DECIMAL(18,2)) AS forecasted_revenue
FROM latest l
JOIN coefficients c ON l.category = c.category
ORDER BY forecasted_revenue DESC;
