-- Project: Conversion Funnel Analysis
-- Tool: Google BigQuery
-- Description: Tracks the session-to-registration-to-order funnel by month and country,
--              and separately measures what share of order sessions coincide with the
--              session in which the account was registered.

-- ============================================================
-- Query 1: Funnel by month and country
-- ============================================================

WITH session_cte AS (
SELECT  DATE_TRUNC(s.date, MONTH) AS month_date,
        sp.country,

        COUNT(DISTINCT s.ga_session_id) AS sessions

FROM    `data-analytics-mate.DA.session` s
JOIN    `data-analytics-mate.DA.session_params` sp
ON      s.ga_session_id = sp.ga_session_id

GROUP BY month_date, sp.country
),

registration_cte AS (
SELECT  DATE_TRUNC(s.date, MONTH) AS month_date,
        sp.country,

        COUNT(DISTINCT acs.ga_session_id) AS registrations

FROM    `data-analytics-mate.DA.account_session` acs
JOIN    `data-analytics-mate.DA.session` s
ON      acs.ga_session_id = s.ga_session_id
JOIN    `data-analytics-mate.DA.session_params` sp
ON      acs.ga_session_id = sp.ga_session_id

GROUP BY month_date, sp.country
),

order_cte AS (
SELECT  DATE_TRUNC(s.date, MONTH) AS month_date,
        sp.country,

        COUNT(DISTINCT o.ga_session_id) AS order_sessions,
        SUM(p.price) AS revenue

FROM    `data-analytics-mate.DA.order` o
JOIN    `data-analytics-mate.DA.product` p
ON      o.item_id = p.item_id
JOIN    `data-analytics-mate.DA.session` s
ON      o.ga_session_id = s.ga_session_id
JOIN    `data-analytics-mate.DA.session_params` sp
ON      o.ga_session_id = sp.ga_session_id

GROUP BY month_date, sp.country
)

SELECT  sc.month_date,
        sc.country,

        sc.sessions,
        COALESCE(rc.registrations, 0) AS registrations,
        COALESCE(oc.order_sessions, 0) AS order_sessions,
        COALESCE(oc.revenue, 0) AS revenue,

        ROUND(SAFE_DIVIDE(rc.registrations, sc.sessions) * 100, 2) AS session_to_registration_rate,
        ROUND(SAFE_DIVIDE(oc.order_sessions, rc.registrations) * 100, 2) AS registration_to_order_rate,
        ROUND(SAFE_DIVIDE(oc.order_sessions, sc.sessions) * 100, 2) AS session_to_order_rate

FROM    session_cte sc
LEFT JOIN registration_cte rc
ON      sc.month_date = rc.month_date
AND     sc.country = rc.country
LEFT JOIN order_cte oc
ON      sc.month_date = oc.month_date
AND     sc.country = oc.country

ORDER BY sc.month_date, sc.sessions DESC;


-- ============================================================
-- Query 2: Share of order sessions that coincide with a
--          registration session, by month
-- ============================================================

WITH registration_sessions AS (
SELECT  DISTINCT ga_session_id
FROM    `data-analytics-mate.DA.account_session`
)

SELECT  DATE_TRUNC(s.date, MONTH) AS month_date,

        COUNT(DISTINCT o.ga_session_id) AS order_sessions,
        COUNT(DISTINCT CASE WHEN rs.ga_session_id IS NOT NULL THEN o.ga_session_id END) AS order_sessions_with_registration,
        COUNT(DISTINCT CASE WHEN rs.ga_session_id IS NULL THEN o.ga_session_id END) AS order_sessions_without_registration,

        ROUND(SAFE_DIVIDE(
            COUNT(DISTINCT CASE WHEN rs.ga_session_id IS NOT NULL THEN o.ga_session_id END),
            COUNT(DISTINCT o.ga_session_id)
        ) * 100, 2) AS pct_orders_with_registration_session

FROM    `data-analytics-mate.DA.order` o
JOIN    `data-analytics-mate.DA.session` s
ON      o.ga_session_id = s.ga_session_id
LEFT JOIN registration_sessions rs
ON      o.ga_session_id = rs.ga_session_id

GROUP BY month_date
ORDER BY month_date;
