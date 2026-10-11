-- Project: ab_test_analysis
-- Tool: Google BigQuery
-- Description: A/B test metrics (sessions, sessions with orders, accounts
--              created during registration sessions, and event counts)
--              by date, country, continent, device, channel, test and test_group.
--              Always filter by test in BI: ~53% of sessions take part
--              in more than one test.

WITH session_info AS (
  SELECT  s.ga_session_id,
  
          s.date,
          sp.country,
          sp.continent,
          sp.device,
          sp.channel,
          ab.test,
          ab.test_group
  FROM    `DA.ab_test` ab
  JOIN    `DA.session` s
  ON      ab.ga_session_id = s.ga_session_id
  JOIN    `DA.session_params` sp
  ON      s.ga_session_id = sp.ga_session_id
),

session_agg AS (
  SELECT  date, country, continent, device, channel, test, test_group,
          COUNT(DISTINCT ga_session_id) AS session_cnt
  FROM    session_info
  GROUP BY ALL
),

account_agg AS (
  SELECT  si.date, si.country, si.continent, si.device, si.channel, si.test, si.test_group,
          COUNT(DISTINCT acs.account_id) AS new_account_cnt
  FROM    `DA.account_session` acs
  JOIN    session_info si
  ON      acs.ga_session_id = si.ga_session_id
  GROUP BY ALL
),

session_order_agg AS (
  SELECT  si.date, si.country, si.continent, si.device, si.channel, si.test, si.test_group,
          COUNT(DISTINCT o.ga_session_id) AS session_with_order_cnt
  FROM    `DA.order` o
  JOIN    session_info si
  ON      o.ga_session_id = si.ga_session_id
  GROUP BY ALL
),

event_agg AS (
  SELECT  si.date, si.country, si.continent, si.device, si.channel, si.test, si.test_group,
          ep.event_name,
          COUNT(ep.ga_session_id) AS event_cnt
  FROM    `DA.event_params` ep
  JOIN    session_info si
  ON      ep.ga_session_id = si.ga_session_id
  GROUP BY ALL
)


SELECT  date, country, continent, device, channel, test, test_group,
        'session' AS event_name,
        session_cnt AS value
FROM    session_agg

UNION ALL

SELECT  date, country, continent, device, channel, test, test_group,
        'new_account' AS event_name,
        new_account_cnt AS value
FROM    account_agg

UNION ALL

SELECT  date, country, continent, device, channel, test, test_group,
        'session_with_orders' AS event_name,
        session_with_order_cnt AS value
FROM    session_order_agg

UNION ALL

SELECT  date, country, continent, device, channel, test, test_group,
        event_name,
        event_cnt AS value
FROM    event_agg;
