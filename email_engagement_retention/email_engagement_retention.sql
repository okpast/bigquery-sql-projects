-- Project: Email Engagement Retention Analysis
-- Tool: Google BigQuery
-- Description: Groups accounts into monthly registration cohorts and tracks send-based
--              and open-based email engagement retention (both absolute and month-over-month
--              relative) in each following month. Fills missing months with zero-engagement
--              rows so relative retention always compares against the true previous month.

WITH account_registration_cte AS (
SELECT  a.id AS account_id,
        s.date AS registration_date

FROM    `data-analytics-mate.DA.account` a
JOIN    `data-analytics-mate.DA.account_session` acs
ON      a.id = acs.account_id
JOIN    `data-analytics-mate.DA.session` s
ON      acs.ga_session_id = s.ga_session_id
),

email_agg_cte AS (
SELECT  acs.account_id,
        DATE_ADD(s.date, INTERVAL es.sent_date DAY) AS sent_date,

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

GROUP BY acs.account_id, sent_date
),

cohort_agg_cte AS (
SELECT  DATE_TRUNC(af.registration_date, MONTH) AS cohort_month,
        DATE_DIFF(DATE_TRUNC(ea.sent_date, MONTH), DATE_TRUNC(af.registration_date, MONTH), MONTH) AS month_number,

        COUNT(DISTINCT af.account_id) AS sent_engaged_accounts,
        COUNT(DISTINCT CASE WHEN ea.open_cnt > 0 THEN af.account_id END) AS open_engaged_accounts,

        SUM(ea.sent_cnt) AS sent_cnt,
        SUM(ea.open_cnt) AS open_cnt,
        SUM(ea.click_cnt) AS click_cnt

FROM    account_registration_cte af
JOIN    email_agg_cte ea
ON      af.account_id = ea.account_id
WHERE   ea.sent_date >= af.registration_date

GROUP BY cohort_month, month_number
),

cohort_size_cte AS (
SELECT  DATE_TRUNC(registration_date, MONTH) AS cohort_month,
        COUNT(DISTINCT account_id) AS cohort_size

FROM    account_registration_cte
GROUP BY cohort_month
),

-- Builds one row per (cohort_month, month_number) from 0 up to the last month
-- that cohort actually has data for, so LAG() always compares true consecutive months.
cohort_months_range_cte AS (
SELECT  cs.cohort_month,
        month_num AS month_number

FROM    cohort_size_cte cs
JOIN    (
    SELECT  cohort_month,
            MAX(month_number) AS max_month_number
    FROM    cohort_agg_cte
    GROUP BY cohort_month
) mx
ON      cs.cohort_month = mx.cohort_month
CROSS JOIN UNNEST(GENERATE_ARRAY(0, mx.max_month_number)) AS month_num
)

SELECT  *,
        ROUND(SAFE_DIVIDE(
            sent_engaged_accounts,
            LAG(sent_engaged_accounts) OVER (PARTITION BY cohort_month ORDER BY month_number)
        ) * 100, 2) AS sent_relative_retention_rate,
        ROUND(SAFE_DIVIDE(
            open_engaged_accounts,
            LAG(open_engaged_accounts) OVER (PARTITION BY cohort_month ORDER BY month_number)
        ) * 100, 2) AS open_relative_retention_rate

FROM (SELECT  cmr.cohort_month,
              cs.cohort_size,
              cmr.month_number,

              COALESCE(agg.sent_engaged_accounts, 0) AS sent_engaged_accounts,
              ROUND(SAFE_DIVIDE(COALESCE(agg.sent_engaged_accounts, 0), cs.cohort_size) * 100, 2) AS sent_retention_rate,

              COALESCE(agg.open_engaged_accounts, 0) AS open_engaged_accounts,
              ROUND(SAFE_DIVIDE(COALESCE(agg.open_engaged_accounts, 0), cs.cohort_size) * 100, 2) AS open_retention_rate,

              COALESCE(agg.sent_cnt, 0) AS sent_cnt,
              COALESCE(agg.open_cnt, 0) AS open_cnt,
              COALESCE(agg.click_cnt, 0) AS click_cnt,

              ROUND(SAFE_DIVIDE(COALESCE(agg.open_cnt, 0), COALESCE(agg.sent_cnt, 0)) * 100, 2) AS open_rate,
              ROUND(SAFE_DIVIDE(COALESCE(agg.click_cnt, 0), COALESCE(agg.sent_cnt, 0)) * 100, 2) AS click_rate

      FROM    cohort_months_range_cte cmr
      JOIN    cohort_size_cte cs
      ON      cmr.cohort_month = cs.cohort_month
      LEFT JOIN cohort_agg_cte agg
      ON      cmr.cohort_month = agg.cohort_month
      AND     cmr.month_number = agg.month_number
)
ORDER BY cohort_month, month_number;
