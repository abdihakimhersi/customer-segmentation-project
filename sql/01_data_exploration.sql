-- Explorative Data 1: Understanding Order Status
-- what consistutes a valid customer purchase?
SELECT
MIN(order_purchase_timestamp) AS first_approved_purchase,
MAX(order_purchase_timestamp) AS last_approved_purchase
FROM 
`my-first-project-462019.brazilian_ecommerce.orders_data`
WHERE
  order_status = 'approved'

/*
MY FINDING:
- delivered: 96,478 orders → These are successful purchases
- canceled/unavailable: ~1,200 orders → Should be excluded
- Other statuses: Transitional states

MY DECISION: 
Only count 'delivered' orders for customer scoring.
This removes cancelled/returned purchases from analysis.
*/

-- Explorative Data 2: The Repeat Purchase Count
-- can we i use RFM?
SELECT
order_status,
COUNT(*) as order_count,
COUNT(DISTINCT(customer_id)) as customer_count,
FROM `my-first-project-462019.brazilian_ecommerce.orders_data`
GROUP BY
  order_status

/*
MY FINDING:
96,478 customers = 96,478 orders
Every customer has exactly 1 delivered order!

MY ADAPTATION:
Traditional RFM (Recency, Frequency, Monetary) impossible.
Must create new model: Recency + Monetary only.
Frequency removed (always = 1 for everyone).
*/

-- Explorative Data 3: Purchase Value Reality Check
-- How should we measure monetary value
SELECT
MIN(customer_metrics.recency_days) AS min_days,
MAX(customer_metrics.recency_days) AS max_days,
MIN(customer_metrics.total_spent) AS min_spend,
MAX(customer_metrics.total_spent) AS max_spend
FROM (
SELECT
  delivery.customer_id,
  SUM(cost.price + cost.freight_value) as total_spent,
  DATE_DIFF(DATE('2018-08-29'), DATE(delivery.order_purchase_timestamp), DAY) as recency_days
FROM
  `my-first-project-462019.brazilian_ecommerce.orders_data` as delivery
INNER JOIN
  `my-first-project-462019.brazilian_ecommerce.order_items_data` as cost ON delivery.order_id = cost.order_id
WHERE
  order_status = 'delivered'
GROUP BY
  delivery.customer_id,
  recency_days
ORDER BY
  total_spent DESC, recency_days ASC) AS customer_metrics

/*
MY DISCOVERY:
- Min: $9.59, Max: $13,664, Avg: $159.83
- Extreme range! Normal scaling will fail.

MY SOLUTION:
Tried min-max scaling first → failed (scores 1.0-1.3 only).
Switched to PERCENTILE RANKING → worked perfectly!
*/

-- DISCOVERY 4: Timeframe for "Recency"
-- What's our "today" for calculating days since purchase?
SELECT
  MIN(order_purchase_timestamp) as first_purchase,
  MAX(order_purchase_timestamp) as last_purchase
FROM `my-first-project-462019.brazilian_ecommerce.orders_data`
WHERE order_status = 'delivered';

/*
MY FINDING:
Last purchase: 2018-08-29
This becomes our "analysis date" for all recency calculations.
Customers measured as "days since 2018-08-29".
*/

-- DISCOVERY 5: Testing Our Initial Model
-- first scoring attempt failed
SELECT
CASE
  WHEN final_score < 30 THEN 'At Risk (0-29%)'
  WHEN final_score < 50 THEN 'Average (30-49%)'
  WHEN final_score < 60 THEN 'Loyal (50-59%)'
  ELSE 'Champion (60%+)'
END as customer_segmentation,
COUNT(*) as customer_count,
ROUND(AVG(final_score),1) as average_final_score,
ROUND(AVG(recency_score),1) as average_recency_score,
ROUND(AVG(monetary_score),1) as average_monetary_score
FROM(
SELECT
recency_score,
monetary_score,
recency_score*0.65 + monetary_score*0.35 as final_score
FROM(
SELECT
((customer_metrics.total_spent - 9.59)/(13664.08-9.59))*100 as monetary_score,
100 - (((customer_metrics.recency_days - 0)/(713-0))*100) as recency_score,
FROM (
SELECT
  delivery.customer_id,
  SUM(cost.price + cost.freight_value) as total_spent,
  DATE_DIFF(DATE('2018-08-29'), DATE(delivery.order_purchase_timestamp), DAY) as recency_days
FROM
  `my-first-project-462019.brazilian_ecommerce.orders_data` as delivery
INNER JOIN
  `my-first-project-462019.brazilian_ecommerce.order_items_data` as cost ON delivery.order_id = cost.order_id
WHERE
  order_status = 'delivered'
GROUP BY
  delivery.customer_id,
  recency_days
ORDER BY
  total_spent DESC, recency_days ASC) AS customer_metrics))
GROUP BY customer_segmentation
ORDER BY
CASE customer_segmentation
  WHEN 'Champion (60%+)' THEN 1
  WHEN 'Loyal (50-59%)' THEN 2
  WHEN 'Average (30-49%)' THEN 3
  WHEN 'At Risk (0-29%)' THEN 4
END;

/*
MY DIAGNOSIS:
Recency scores: 0-100 (good spread)
Monetary scores: 1.0-1.3 (terrible spread!)

MY FIX:
Changed monetary calculation to:
PERCENT_RANK() OVER(ORDER BY total_spent) * 100
Now both scores have meaningful 0-100 ranges.
*/

/*
WHAT I LEARNED FROM THE DATA:

1. REALITY CHECK: Data often contradicts assumptions
   - Assumed: Multiple purchases per customer
   - Reality: Only 1 purchase each → model adaptation needed

2. SCALING MATTERS: Math must match data distribution
   - First attempt: Min-max scaling failed
   - Solution: Percentile ranking saved the model

3. BUSINESS LOGIC: Clean data = clean decisions
   - Excluding cancelled orders = accurate customer value
   - Using last date = consistent recency measurement

4. ITERATIVE PROCESS: Try → Fail → Learn → Improve
   - Initial RFM → failed
   - Recency+Monetary → worked
   - Min-max scaling → failed  
   - Percentile ranking → worked!

THIS EXPLORATION SHAPED OUR FINAL MODEL:
• 65% Recency (days since 2018-08-29, inverted 0-100 scale)
• 35% Monetary (percentile ranking 0-100 scale)
• Segments: Champion (60+), Loyal (50-59), Average (30-49), At Risk (0-29)
*/


