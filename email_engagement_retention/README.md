# Email Engagement Retention Analysis

SQL project built using Google BigQuery.

## Description

Groups accounts into monthly registration cohorts and tracks both send-based and 
open-based email engagement retention in each following month — measured both as 
absolute retention (against the original cohort size) and relative retention 
(month-over-month).

**Data Source:** `data-analytics-mate.DA`

## Metrics

- Cohort Size
- Month Number (months since registration)
- Sent-Based Engaged Accounts / Retention Rate (absolute, from cohort size)
- Open-Based Engaged Accounts / Retention Rate (absolute, from cohort size)
- Sent / Open Relative Retention Rate (month-over-month, from previous month's engaged accounts)
- Sent / Open / Click Counts
- Open Rate / Click Rate

## Notes

- Absolute retention rate = engaged accounts in month N / original cohort size. 
  Shows what share of the original cohort is still active.
- Relative retention rate = engaged accounts in month N / engaged accounts in month N-1. 
  Shows month-over-month drop-off among those still active.
- "Engaged" for sent-based metrics means the account received at least one email 
  that month; for open-based metrics, it means the account opened at least one email.

## SQL

[email_engagement_retention.sql](email_engagement_retention.sql)
