-- Project: User Engagement Analysis
-- Tool: Google BigQuery
-- Description: Analyzes average user engagement time and device ranking by country, device, and date.

WITH engagement_cte AS (
SELECT  ga_session_id,
        MAX(params.value.int_value) AS engagement_time_msec

FROM    `data-analytics-mate.DA.event_params`,
        UNNEST(event_params) AS params
WHERE   params.key = 'engagement_time_msec'

GROUP BY ga_session_id
)

SELECT  s.date,
        DATE_TRUNC(s.date, MONTH) AS month_date,

        sp.country,
        sp.device,

        COUNT(*) AS sessions,

        AVG(e.engagement_time_msec) / 60000 AS avg_engagement_time_min

FROM    `data-analytics-mate.DA.session` s
JOIN    `data-analytics-mate.DA.session_params` sp
ON      s.ga_session_id = sp.ga_session_id

JOIN    engagement_cte e
ON      s.ga_session_id = e.ga_session_id

GROUP BY  s.date, month_date, sp.country, sp.device
ORDER BY  s.date, sp.country;
