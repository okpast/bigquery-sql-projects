# Conversion Funnel Analysis

SQL project built using Google BigQuery.

## Description

Tracks the funnel from session to registration to order, broken down by month and 
country, and separately measures what share of order sessions actually coincide 
with the session in which the account was registered.

**Data Source:** `data-analytics-mate.DA`

## Metrics

**Funnel by month and country:**
- Sessions
- Registrations
- Order Sessions
- Revenue
- Session → Registration Rate
- Registration → Order Rate
- Session → Order Rate (overall funnel conversion)

**Order/registration session overlap, by month:**
- Order Sessions
- Order Sessions With a Registration Session
- Order Sessions Without Registration Session
- % of Orders With a Registration Session

## Notes

Only about 8% of order sessions coincide with the session in which the account 
was registered. The remaining ~92% of orders happen in sessions with no 
registration event on record. Because `order` is not linked to `account_id` 
directly, these could be either guest purchases or returning accounts using a 
new session — the dataset does not allow distinguishing between the two.

This also explains why `registration_to_order_rate` in the month/country breakdown 
can exceed 100% (seen up to ~200% in the data): it counts all order sessions in a 
given month/country against registrations from that same month/country, regardless 
of whether the buyer registered in that specific session.

- `(not set)` as a country value reflects sessions where GA could not resolve 
  geography — this is a data artifact, not a query error.
- Rates show as `null` when the denominator (sessions or registrations) is zero 
  for that month/country combination.

## SQL

[conversion_funnel.sql](conversion_funnel.sql)
