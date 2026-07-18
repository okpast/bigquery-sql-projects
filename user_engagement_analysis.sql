-- Project: User Engagement Analysis
-- Tool: Google BigQuery
-- Description: Analyzes average engagement time by country and device.

WITH engagement_cte AS (
SELECT  ga_session_id,
        MAX(params.value.int_value) AS time_msec

FROM    `data-analytics-mate.DA.event_params`,
        UNNEST(event_params) AS params
WHERE   params.key = 'engagement_time_msec'

GROUP BY ga_session_id
)

SELECT  sp.country,
        sp.device,

        COUNT(*) AS sessions,
        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS session_share_percent,

        ROUND(AVG(e.time_msec) / 60000, 2) AS avg_time_min,
        
        RANK() OVER (PARTITION BY sp.country ORDER BY AVG(e.time_msec) DESC) AS device_rank

FROM    `data-analytics-mate.DA.session_params` sp

JOIN    engagement_cte e
ON      sp.ga_session_id = e.ga_session_id

GROUP BY sp.country, sp.device
ORDER BY sp.country, device_rank;

