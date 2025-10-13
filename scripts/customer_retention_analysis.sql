-- customer_retention_analysis
-- Analyze monthly customer retention (cohort-based)

WITH first_purchase AS (
    SELECT
        customer_key,
        -- Truncate to first day of the month
        DATEFROMPARTS(YEAR(MIN(order_date)), MONTH(MIN(order_date)), 1) AS cohort_month
    FROM gold.fact_sales
    GROUP BY customer_key
),
customer_activity AS (
    SELECT
        f.customer_key,
        DATEFROMPARTS(YEAR(f.order_date), MONTH(f.order_date), 1) AS active_month,
        fp.cohort_month
    FROM gold.fact_sales f
    INNER JOIN first_purchase fp
        ON f.customer_key = fp.customer_key
),
retention AS (
    SELECT
        cohort_month,
        DATEDIFF(MONTH, cohort_month, active_month) AS months_after_cohort,
        COUNT(DISTINCT customer_key) AS active_customers
    FROM customer_activity
    GROUP BY cohort_month, DATEDIFF(MONTH, cohort_month, active_month)
)
SELECT
    cohort_month,
    months_after_cohort,
    active_customers,
    ROUND(
        active_customers * 100.0 /
        MAX(active_customers) OVER (PARTITION BY cohort_month),
        2
    ) AS retention_rate
FROM retention
ORDER BY cohort_month, months_after_cohort;
