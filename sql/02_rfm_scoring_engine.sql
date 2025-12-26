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
  total_spent DESC, recency_days ASC) AS customer_metrics)
