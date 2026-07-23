-- Project: Account Email Performance
-- Tool: Google BigQuery
-- Description: Analyzes account activity, email performance, and country rankings.

WITH  account_agg AS (
SELECT  s.date,
        sp.country,

        a.send_interval,
        a.is_verified,
        a.is_unsubscribed,

        COUNT(DISTINCT a.id) AS account_cnt,
        0 AS sent_msg,
        0 AS open_msg,
        0 AS visit_msg
  
FROM    `data-analytics-mate.DA.account` a
JOIN    `data-analytics-mate.DA.account_session` acs
ON      a.id = acs.account_id

JOIN    `data-analytics-mate.DA.session` s
ON      acs.ga_session_id = s.ga_session_id
JOIN    `data-analytics-mate.DA.session_params` sp
ON      acs.ga_session_id = sp.ga_session_id

GROUP BY 1, 2, 3, 4, 5
),

email_agg AS (
SELECT  DATE_ADD(s.date, INTERVAL es.sent_date DAY) AS date,
        sp.country,
        
        a.send_interval,
        a.is_verified,
        a.is_unsubscribed,
                
        0 AS account_cnt,
        COUNT(DISTINCT es.id_message) AS sent_msg,
        COUNT(DISTINCT eo.id_message) AS open_msg,
        COUNT(DISTINCT ev.id_message) AS visit_msg

FROM    `data-analytics-mate.DA.email_sent` es
LEFT JOIN `data-analytics-mate.DA.email_open` eo
ON      es.id_message = eo.id_message
LEFT JOIN `data-analytics-mate.DA.email_visit` ev
ON      es.id_message = ev.id_message

JOIN    `data-analytics-mate.DA.account` a
ON      es.id_account = a.id
JOIN    `data-analytics-mate.DA.account_session` acs
ON      a.id = acs.account_id

JOIN    `data-analytics-mate.DA.session` s
ON      acs.ga_session_id = s.ga_session_id
JOIN    `data-analytics-mate.DA.session_params` sp
ON      acs.ga_session_id = sp.ga_session_id

GROUP BY 1, 2, 3, 4, 5
),

combined_agg AS (
SELECT  date,
        country,
        
        send_interval,
        is_verified,
        is_unsubscribed,

        SUM(account_cnt) AS account_cnt,
        SUM(sent_msg) AS sent_msg,
        SUM(open_msg) AS open_msg,
        SUM(visit_msg) AS visit_msg

FROM  ( SELECT  *
        FROM    account_agg
        UNION ALL
        SELECT  *
        FROM    email_agg
      )

GROUP BY 1, 2, 3, 4, 5    
),

country_agg AS (
SELECT  *,
        SUM(account_cnt) OVER (PARTITION BY country) AS country_account_total,
        SUM(sent_msg) OVER (PARTITION BY country) AS country_sent_total

FROM    combined_agg
),

final_cte AS (
SELECT  *,
        DENSE_RANK() OVER (ORDER BY country_account_total DESC) AS country_account_rank,
        DENSE_RANK() OVER (ORDER BY country_sent_total DESC) AS country_sent_rank

FROM  country_agg
)

SELECT  date,
        country,
        
        send_interval,
        is_verified,
        is_unsubscribed,

        account_cnt,
        sent_msg,
        open_msg,
        visit_msg,

        country_account_total,
        country_sent_total,

        country_account_rank,        
        country_sent_rank

FROM    final_cte
WHERE   country_account_rank <= 10
OR      country_sent_rank <= 10
