-- Project: Marketing Cost Efficiency Analysis
-- Tool: Google BigQuery
-- Description: Compares monthly paid search cost against registrations, orders, and
--              revenue to calculate cost per registration, cost per order, and ROAS.

WITH cost_cte AS (
SELECT  DATE_TRUNC(date, MONTH) AS month_date,
        SUM(cost) AS cost

FROM    `data-analytics-mate.DA.paid_search_cost`
GROUP BY month_date
),

registration_cte AS (
SELECT  DATE_TRUNC(s.date, MONTH) AS month_date,
        COUNT(DISTINCT acs.ga_session_id) AS registrations

FROM    `data-analytics-mate.DA.account_session` acs
JOIN    `data-analytics-mate.DA.session` s
ON      acs.ga_session_id = s.ga_session_id

GROUP BY month_date
),

order_cte AS (
SELECT  DATE_TRUNC(s.date, MONTH) AS month_date,

        COUNT(DISTINCT o.ga_session_id) AS order_sessions,
        SUM(p.price) AS revenue

FROM    `data-analytics-mate.DA.order` o
JOIN    `data-analytics-mate.DA.product` p
ON      o.item_id = p.item_id
JOIN    `data-analytics-mate.DA.session` s
ON      o.ga_session_id = s.ga_session_id

GROUP BY month_date
)

SELECT  c.month_date,

        c.cost,
        COALESCE(r.registrations, 0) AS registrations,
        COALESCE(o.order_sessions, 0) AS order_sessions,
        COALESCE(o.revenue, 0) AS revenue,

        ROUND(SAFE_DIVIDE(c.cost, r.registrations), 2) AS cost_per_registration,
        ROUND(SAFE_DIVIDE(c.cost, o.order_sessions), 2) AS cost_per_order,
        ROUND(SAFE_DIVIDE(o.revenue, c.cost), 2) AS roas

FROM    cost_cte c
LEFT JOIN registration_cte r
ON      c.month_date = r.month_date
LEFT JOIN order_cte o
ON      c.month_date = o.month_date

ORDER BY c.month_date;
