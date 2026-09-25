# Marketing Cost Efficiency Analysis

SQL project built using Google BigQuery.

## Description

Compares monthly paid search cost against registrations, orders, and revenue to 
calculate cost per registration, cost per order, and ROAS (return on ad spend).

**Data Source:** `data-analytics-mate.DA`

## Metrics

- Monthly Cost
- Registrations
- Order Sessions
- Revenue
- Cost per Registration
- Cost per Order
- ROAS (Revenue / Cost)

## Notes

- `paid_search_cost` has no channel, campaign, or country breakdown — it is a single 
  daily total. As a result, registrations, order sessions, and revenue in this query 
  include all traffic (paid and organic), not just sessions attributable to paid search. 
  Cost-per-metric figures should be read as an overall efficiency indicator for the 
  period, not as a precise paid-search-only attribution.
- Rates show as `null` when the denominator (registrations or order sessions) is zero 
  for that month.

## SQL

[marketing_cost_efficiency.sql](marketing_cost_efficiency.sql)
