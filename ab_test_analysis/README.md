# A/B Test Analysis

## Description

Metrics for A/B tests by date, country, device, continent, channel, test, and test group, combining sessions, sessions with orders, accounts created during registration sessions, and event counts in a single table.

## Dataset

`data-analytics-mate.DA`

## Metrics

- Sessions
- Sessions with orders
- Accounts created during registration sessions
- Event counts by event name

## Notes

- The output uses `event_name` and `value` to store different metrics in a single table.
- Always filter by `test` in BI reports because approximately 53% of sessions participate in more than one test.
- Metrics are aggregated by date, country, device, continent, channel, test, and test group.
- Accounts are counted using distinct `account_id` values from `account_session` records linked to registration sessions.

## SQL

[ab_test_analysis.sql](ab_test_analysis.sql)
