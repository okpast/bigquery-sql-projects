-- Project: Sent Email Metrics Analysis
-- Tool: Google BigQuery
-- Description: Analyzes marketing performance and email campaign metrics by month.
--
-- Metrics:
-- Revenue
-- Marketing Cost
-- Emails Sent
-- Email Open Rate
-- Email Click Rate
-- Registration Count

WITH revenue_cte AS (
SELECT  s.date,
        SUM(p.price) AS revenue
FROM    `data-analytics-mate.DA.order`  o
JOIN    `data-analytics-mate.DA.product` p
ON      o.item_id = p.item_id

JOIN    `data-analytics-mate.DA.session` s
ON      o.ga_session_id = s.ga_session_id
GROUP BY s.date
),

cost_cte AS (
SELECT  psc.date,
        SUM(psc.cost) AS cost
FROM    `data-analytics-mate.DA.paid_search_cost` psc
GROUP BY psc.date
),

email_cte AS (
SELECT  DATE_ADD(s.date, INTERVAL es.sent_date DAY) AS sent_date,
        COUNT(DISTINCT es.id_message) AS sent_cnt,
        COUNT(DISTINCT eo.id_message) AS open_cnt,
        COUNT(DISTINCT ev.id_message) AS click_cnt
        
FROM    `data-analytics-mate.DA.email_sent` es
LEFT JOIN `data-analytics-mate.DA.email_open` eo
ON      es.id_message = eo.id_message
LEFT JOIN `data-analytics-mate.DA.email_visit` ev
ON      es.id_message = ev.id_message

JOIN    `data-analytics-mate.DA.account_session` acs
ON      es.id_account = acs.account_id
JOIN    `data-analytics-mate.DA.session` s
ON      acs.ga_session_id = s.ga_session_id
GROUP BY  1
),

registration_cte AS (
SELECT  s.date,
        COUNT(DISTINCT acs.account_id) AS account_cnt

FROM    `data-analytics-mate.DA.account_session` acs
JOIN    `data-analytics-mate.DA.session` s
ON      acs.ga_session_id = s.ga_session_id
GROUP BY  s.date
),

result_cte AS (
SELECT  date,
        revenue,
        0 AS cost,
        0 AS sent_cnt,
        0 AS open_cnt,
        0 AS click_cnt,
        0 AS account_cnt          
FROM  revenue_cte
UNION ALL
SELECT  date,
        0 AS revenue,
        cost,
        0 AS sent_cnt,
        0 AS open_cnt,
        0 AS click_cnt,
        0 AS account_cnt        
FROM  cost_cte
UNION ALL
SELECT  sent_date,
        0 AS revenue,
        0 AS cost,
        sent_cnt,
        open_cnt,
        click_cnt,
        0 AS account_cnt
FROM  email_cte
UNION ALL
SELECT  date,
        0 AS revenue,
        0 AS cost,
        0 AS sent_cnt,
        0 AS open_cnt,
        0 AS click_cnt,
        account_cnt
FROM  registration_cte
)

SELECT  DATE_TRUNC(date, MONTH) AS month_date,
        --EXTRACT(YEAR FROM date) AS year,
        --EXTRACT(MONTH FROM date) AS month,
        
        SUM(revenue)  AS revenue,
        SUM(cost) AS cost,
        SUM(sent_cnt) AS sent_cnt,

        SAFE_DIVIDE(SUM(open_cnt), SUM(sent_cnt)) * 100 AS open_rate,
        SAFE_DIVIDE(SUM(click_cnt), SUM(sent_cnt)) * 100 AS click_rate,
        
        SUM(account_cnt) AS registration_cnt
FROM    result_cte
        
GROUP BY month_date
ORDER BY month_date
