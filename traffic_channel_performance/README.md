# Traffic Channel Performance Analysis

SQL project built using Google BigQuery.

## Description

Compares sessions, order sessions, revenue, and conversion rate across traffic 
channels and mediums by month, limited to the top 3 channels by total revenue. 
Shows each row's share of all monthly sessions and revenue.

**Data Source:** `data-analytics-mate.DA`

## Metrics

- Sessions
- Order Sessions
- Revenue
- Conversion Rate (Order Sessions / Sessions)
- Revenue per Session
- % of Monthly Sessions
- % of Monthly Revenue
- Channel Total Revenue (whole period)
- Channel Revenue Rank

## Notes

- Only the top 3 channels by total revenue over the whole period are shown. The 
  rank is calculated at the `channel` level, not per `channel` + `medium` pair, 
  because some combinations in the source data do not align (e.g. `Paid Search` 
  with `organic` medium).
- `% of Monthly Sessions` and `% of Monthly Revenue` are calculated against all 
  channels, before the top-3 filter is applied, so the shares are not inflated.
- Channel and medium values are shown as they appear in `session_params`, including 
  placeholders such as `(none)`, `<Other>` and `(data deleted)`.
- Rates show as `null` when the denominator (sessions) is zero.

## SQL

[traffic_channel_performance.sql](traffic_channel_performance.sql)
