-- Project: Revenue Prediction Fulfillment
-- Tool: Google BigQuery
-- Description: Compares actual and predicted revenue, calculates cumulative values using window functions, and measures revenue fulfillment over time.

WITH  revenue_predict_cte AS (
SELECT  s.date,
        SUM(CAST(p.price AS NUMERIC)) AS revenue,
        0 AS predict
FROM    `data-analytics-mate.DA.order`  o
JOIN    `data-analytics-mate.DA.product` p
ON      o.item_id = p.item_id

JOIN    `data-analytics-mate.DA.session` s
ON      o.ga_session_id = s.ga_session_id
GROUP BY s.date

UNION ALL

SELECT  date,
        0 AS revenue,
        SUM(CAST(predict AS NUMERIC)) AS predict
FROM    `data-analytics-mate.DA.revenue_predict`
GROUP BY date
)

SELECT  date,
        revenue,
        SUM(revenue) OVER (ORDER BY date) AS cumulative_revenue,
        predict,
        SUM(predict) OVER (ORDER BY date) AS cumulative_predict, 
        
        ROUND(SAFE_DIVIDE(SUM(revenue) OVER (ORDER BY date), SUM(predict) OVER (ORDER BY date)) * 100, 2) AS percentage

FROM( SELECT  date,
              SUM(revenue) AS revenue,
              SUM(predict) AS predict
      FROM    revenue_predict_cte
      GROUP BY date
    )
ORDER BY date DESC;
