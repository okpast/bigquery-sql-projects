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
- Sent-Based Engaged Accounts / Absolute Retention Rate
- Open-Based Engaged Accounts / Absolute Retention Rate
- Sent-Based / Open-Based Relative Retention Rate
- Sent / Open / Click Counts
- Open Rate / Click Rate

## Notes

- Absolute retention rate = engaged accounts in month N / original cohort size. 
  Shows what share of the original cohort remains engaged.

- Relative retention rate = engaged accounts in month N / engaged accounts in month N-1. 
  Shows the month-over-month change in engaged account count, not a tracked overlap 
  of the same accounts between months. Months with zero engaged accounts are included 
  explicitly (not skipped), so this comparison is always against the true previous 
  calendar month.

- Sent-based engagement means the account received at least one email during the month.
- Open-based engagement means the account opened at least one email during the month.

## SQL

[email_engagement_retention.sql](email_engagement_retention.sql)
