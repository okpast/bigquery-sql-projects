-- Project: Registration and Revenue Analysis
-- Tool: Google BigQuery
-- Description: Analyzes registrations, revenue, and email metrics by country and date.

WITH registration_cte AS (
SELECT  sp.country,
        s.date,

        COUNT(s.ga_session_id) AS session_cnt,
        COUNT(acs.account_id) AS account_cnt

FROM    `data-analytics-mate.DA.session` s
JOIN    `data-analytics-mate.DA.session_params` sp
ON      s.ga_session_id = sp.ga_session_id
LEFT JOIN `data-analytics-mate.DA.account_session` acs
ON      s.ga_session_id = acs.ga_session_id

GROUP BY sp.country, s.date
),

revenue_cte AS (
SELECT  sp.country,
        s.date,
        
        SUM(p.price) AS revenue,        
        SUM(CASE WHEN sp.device = 'mobile' THEN p.price ELSE 0 END)  AS revenue_mobile,
        SUM(CASE WHEN sp.operating_system = 'iOS' THEN p.price ELSE 0 END) AS revenue_ios,
        SUM(CASE WHEN sp.operating_system = 'Android' THEN p.price ELSE 0 END) AS revenue_android

FROM    `data-analytics-mate.DA.order`  o
JOIN    `data-analytics-mate.DA.product` p
ON      o.item_id = p.item_id

JOIN    `DA.session` s
ON      o.ga_session_id = s.ga_session_id
JOIN    `DA.session_params` sp
ON      s.ga_session_id = sp.ga_session_id

GROUP BY sp.country, s.date
),

email_cte AS (
SELECT  sp.country,
        s.date,
        
        COUNT(DISTINCT es.id_message) AS sent_msg

FROM    `DA.email_sent` es

JOIN    `DA.account_session` acs
ON      es.id_account = acs.account_id
JOIN    `DA.session` s
ON      acs.ga_session_id = s.ga_session_id
JOIN    `DA.session_params` sp
ON      acs.ga_session_id = sp.ga_session_id

GROUP BY sp.country, s.date
)

SELECT  reg.country, 
        reg.date,
        DATE_TRUNC(reg.date, MONTH) AS month_date,
        
        reg.session_cnt,
        reg.account_cnt,

        ROUND(SAFE_DIVIDE(reg.account_cnt, reg.session_cnt) * 100, 2) AS registration_percent,

        rev.revenue,
        rev.revenue_mobile,
        rev.revenue_ios,
        rev.revenue_android,

        em.sent_msg

FROM    registration_cte AS reg
  
LEFT JOIN revenue_cte AS rev
ON      reg.country = rev.country
AND     reg.date = rev.date

LEFT JOIN email_cte AS em
ON      reg.country = em.country
AND     reg.date = em.date;
