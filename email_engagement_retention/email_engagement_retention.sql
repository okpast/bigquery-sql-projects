-- Project: Email Engagement Retention Analysis
-- Tool: Google BigQuery
-- Description: Groups accounts into monthly registration cohorts and tracks send-based and open-based email engagement retention in each following month.

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

cohort_events_cte AS (
SELECT  af.account_id,
        DATE_TRUNC(af.registration_date, MONTH) AS cohort_month,
        DATE_DIFF(DATE_TRUNC(ea.sent_date, MONTH), DATE_TRUNC(af.registration_date, MONTH), MONTH) AS month_number,

        ea.sent_cnt,
        ea.open_cnt,
        ea.click_cnt

FROM    account_registration_cte af
JOIN    email_agg_cte ea
ON      af.account_id = ea.account_id
WHERE   ea.sent_date >= af.registration_date
),

cohort_size_cte AS (
SELECT  DATE_TRUNC(registration_date, MONTH) AS cohort_month,
        COUNT(DISTINCT account_id) AS cohort_size

FROM    account_registration_cte
GROUP BY cohort_month
)

SELECT  ce.cohort_month,
        cs.cohort_size,
        ce.month_number,

        -- Send-based retention: % of cohort who received at least one email
        COUNT(DISTINCT ce.account_id) AS sent_engaged_accounts,
        ROUND(SAFE_DIVIDE(COUNT(DISTINCT ce.account_id), cs.cohort_size) * 100, 2) AS sent_retention_rate,

        -- Open-based retention: % of cohort who opened at least one email
        COUNT(DISTINCT CASE WHEN ce.open_cnt > 0 THEN ce.account_id END) AS open_engaged_accounts,
        ROUND(SAFE_DIVIDE(COUNT(DISTINCT CASE WHEN ce.open_cnt > 0 THEN ce.account_id END), cs.cohort_size) * 100, 2) AS open_retention_rate,

        SUM(ce.sent_cnt) AS sent_cnt,
        SUM(ce.open_cnt) AS open_cnt,
        SUM(ce.click_cnt) AS click_cnt,

        ROUND(SAFE_DIVIDE(SUM(ce.open_cnt), SUM(ce.sent_cnt)) * 100, 2) AS open_rate,
        ROUND(SAFE_DIVIDE(SUM(ce.click_cnt), SUM(ce.sent_cnt)) * 100, 2) AS click_rate

FROM    cohort_events_cte ce
JOIN    cohort_size_cte cs
ON      ce.cohort_month = cs.cohort_month

GROUP BY ce.cohort_month, cs.cohort_size, ce.month_number
ORDER BY ce.cohort_month, ce.month_number;
