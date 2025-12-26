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
ROUND(AVG(monetary_score),1) as average_monetary_score,
ROUND(COUNT(*)*100/SUM(COUNT(*)) OVER(),1) as segment_precentage
FROM(
SELECT
recency_score,
monetary_score,
recency_score*0.65 + monetary_score*0.35 as final_score
FROM(
SELECT
PERCENT_RANK() OVER(ORDER BY total_spent) * 100 as monetary_score,
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
