-- Project: Traffic Channel Performance Analysis
-- Tool: Google BigQuery
-- Description: Compares sessions, order sessions, revenue, and conversion rate across
--              traffic channels and mediums by month, limited to the top 3 channels
--              ranked by total revenue over the whole period.

WITH session_cte AS (
SELECT  DATE_TRUNC(s.date, MONTH) AS month_date,
        sp.channel,
        sp.medium,

        COUNT(DISTINCT s.ga_session_id) AS sessions

FROM    `data-analytics-mate.DA.session` s
JOIN    `data-analytics-mate.DA.session_params` sp
ON      s.ga_session_id = sp.ga_session_id

GROUP BY month_date, sp.channel, sp.medium
),

order_cte AS (
SELECT  DATE_TRUNC(s.date, MONTH) AS month_date,
        sp.channel,
        sp.medium,

        COUNT(DISTINCT o.ga_session_id) AS order_sessions,
        SUM(CAST(p.price AS NUMERIC)) AS revenue

FROM    `data-analytics-mate.DA.order` o
JOIN    `data-analytics-mate.DA.product` p
ON      o.item_id = p.item_id
JOIN    `data-analytics-mate.DA.session` s
ON      o.ga_session_id = s.ga_session_id
JOIN    `data-analytics-mate.DA.session_params` sp
ON      o.ga_session_id = sp.ga_session_id

GROUP BY month_date, sp.channel, sp.medium
),

channel_agg_cte AS (
SELECT  sc.month_date,
        sc.channel,
        sc.medium,

        sc.sessions,
        COALESCE(oc.order_sessions, 0) AS order_sessions,
        COALESCE(oc.revenue, 0) AS revenue,

        SUM(sc.sessions) OVER (PARTITION BY sc.month_date) AS month_sessions_total,
        SUM(COALESCE(oc.revenue, 0)) OVER (PARTITION BY sc.month_date) AS month_revenue_total,
        SUM(COALESCE(oc.revenue, 0)) OVER (PARTITION BY sc.channel) AS channel_revenue_total

FROM    session_cte sc
LEFT JOIN order_cte oc
ON      sc.month_date = oc.month_date
AND     sc.channel IS NOT DISTINCT FROM oc.channel
AND     sc.medium IS NOT DISTINCT FROM oc.medium
),

ranked_cte AS (
SELECT  *,
        DENSE_RANK() OVER (ORDER BY channel_revenue_total DESC) AS channel_revenue_rank

FROM    channel_agg_cte
)

SELECT  month_date,
        channel,
        medium,

        sessions,
        order_sessions,
        revenue,

        ROUND(SAFE_DIVIDE(order_sessions, sessions) * 100, 2) AS conversion_rate,
        ROUND(SAFE_DIVIDE(revenue, sessions), 2) AS revenue_per_session,

        ROUND(SAFE_DIVIDE(sessions, month_sessions_total) * 100, 2) AS pct_of_monthly_sessions,
        ROUND(SAFE_DIVIDE(revenue, month_revenue_total) * 100, 2) AS pct_of_monthly_revenue,

        channel_revenue_total,
        channel_revenue_rank

FROM    ranked_cte
WHERE   channel_revenue_rank <= 3
ORDER BY month_date, sessions DESC;
