CREATE DATABASE retail_datset;
USE retail_datset;
CREATE TABLE retail_transactions (
    customer_id VARCHAR(10) NOT NULL,
    trans_date DATE,
    tran_amount DECIMAL(10, 2)
);
CREATE TABLE retail_response (
    customer_id VARCHAR(10) NOT NULL,
    response TINYINT
);
-- Check for missing customer_id or response in retail_response
SELECT COUNT(*) AS missing_response 
FROM retail_response 
WHERE customer_id IS NULL OR response IS NULL;

-- Check for missing customer_id, trans_date, or tran_amount in retail_transactions
SELECT COUNT(*) AS missing_transactions 
FROM retail_transactions 
WHERE customer_id IS NULL OR trans_date IS NULL OR tran_amount IS NULL;
-- Check if response is only 0 or 1
SELECT DISTINCT response FROM retail_response;

-- Check for invalid transaction amounts (zero or negative)
SELECT COUNT(*) AS invalid_amounts 
FROM retail_transactions 
WHERE tran_amount <= 0;
-- exploratory data analysis
-- Total customers, transactions, and revenue
SELECT 
    COUNT(DISTINCT customer_id) AS total_customers,
    COUNT(*) AS total_transactions,
    SUM(tran_amount) AS total_revenue
FROM retail_transactions;

-- Avg transaction value
SELECT AVG(tran_amount) AS avg_transaction_value FROM retail_transactions;

-- Response rate (if applicable)
SELECT 
    AVG(response) * 100 AS response_rate_percentage
FROM retail_response;
-- Time-Based Trends (Monthly Sales)
-- Monthly revenue trends
SELECT 
    trans_year,
    trans_month,
    SUM(tran_amount) AS monthly_revenue,
    COUNT(*) AS transaction_count
FROM retail_transactions
GROUP BY trans_year, trans_month
ORDER BY trans_year, trans_month;
-- Customer Segmentation (High/Low Spenders)
-- Top 10 customers by total spending
SELECT 
    customer_id,
    SUM(tran_amount) AS total_spent,
    COUNT(*) AS transaction_count
FROM retail_transactions
GROUP BY customer_id
ORDER BY total_spent DESC
LIMIT 10;

-- Bottom 10 customers (low engagement)
SELECT 
    customer_id,
    SUM(tran_amount) AS total_spent,
    COUNT(*) AS transaction_count
FROM retail_transactions
GROUP BY customer_id
ORDER BY total_spent ASC
LIMIT 10;
-- Advanced Analysis
-- First purchase month per customer (cohort)
WITH first_purchases AS (
    SELECT 
        customer_id,
        MIN(DATE_FORMAT(trans_date, '%Y-%m')) AS cohort_month
    FROM retail_transactions
    GROUP BY customer_id
),
monthly_activity AS (
    SELECT 
        r.customer_id,
        DATE_FORMAT(r.trans_date, '%Y-%m') AS activity_month,
        f.cohort_month
    FROM retail_transactions r
    JOIN first_purchases f ON r.customer_id = f.customer_id
    GROUP BY r.customer_id, activity_month, f.cohort_month
)
SELECT 
    cohort_month,
    activity_month,
    COUNT(DISTINCT customer_id) AS active_customers
FROM monthly_activity
GROUP BY cohort_month, activity_month
ORDER BY cohort_month, activity_month;
-- Response Analysis (Marketing Campaign)
-- Compare spending behavior of responders vs. non-responders
SELECT 
    r.response,
    COUNT(DISTINCT t.customer_id) AS customer_count,
    AVG(t.tran_amount) AS avg_transaction,
    SUM(t.tran_amount) AS total_revenue
FROM retail_transactions t
LEFT JOIN retail_response r ON t.customer_id = r.customer_id
GROUP BY r.response;
-- RFM Analysis (Recency, Frequency, Monetary)
-- RFM Segmentation (assuming latest date is '2023-12-31')
WITH rfm AS (
    SELECT 
        customer_id,
        DATEDIFF('2023-12-31', MAX(trans_date)) AS recency,
        COUNT(*) AS frequency,
        SUM(tran_amount) AS monetary
    FROM retail_transactions
    GROUP BY customer_id
)
SELECT 
    customer_id,
    recency,
    frequency,
    monetary,
    CASE 
        WHEN recency <= 30 AND frequency >= 5 AND monetary >= 500 THEN 'High-Value'
        WHEN recency <= 90 AND frequency >= 3 THEN 'Medium-Value'
        ELSE 'Low-Value'
    END AS rfm_segment
FROM rfm
ORDER BY monetary DESC;