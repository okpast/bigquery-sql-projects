# A/B Test Analysis

## Description

A long-format metrics table for analyzing A/B tests by date, country, device, continent, channel, test, and test group.

## Dataset

`data-analytics-mate.DA`

## Metrics

- Sessions
- Sessions with orders
- New accounts
- Event counts by event name

## Notes

- The output uses `event_name` and `value` to store different metrics in a single table.
- Always filter by `test` in BI reports because approximately 53% of sessions participate in more than one test.
- Metrics are aggregated by date, country, device, continent, channel, test, and test group.
- `new_account` counts distinct account IDs associated with the selected sessions. Confirm that this matches the intended definition of new accounts before interpreting it as a registration count.

## SQL

[ab_test_analysis.sql](ab_test_analysis.sql)
