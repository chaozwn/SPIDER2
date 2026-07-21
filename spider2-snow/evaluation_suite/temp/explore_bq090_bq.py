#!/usr/bin/env python3
"""Try to run gold bq090 SQL against BigQuery public data."""
from google.cloud import bigquery

SQL = """
WITH MomentumTrades AS (
  SELECT StrikePrice - LastPx AS priceDifference
  FROM `bigquery-public-data.cymbal_investments.trade_capture_report`
  WHERE SUBSTR(TargetCompID, 0, 4) = 'MOMO'
    AND (SELECT Side FROM UNNEST(Sides)) = 'LONG'
),
FeelingLuckyTrades AS (
  SELECT StrikePrice - LastPx AS priceDifference
  FROM `bigquery-public-data.cymbal_investments.trade_capture_report`
  WHERE SUBSTR(TargetCompID, 0, 4) = 'LUCK'
    AND (SELECT Side FROM UNNEST(Sides)) = 'LONG'
)
SELECT
  (SELECT AVG(priceDifference) FROM FeelingLuckyTrades) AS luck_avg,
  (SELECT AVG(priceDifference) FROM MomentumTrades) AS momo_avg,
  (SELECT AVG(priceDifference) FROM FeelingLuckyTrades)
    - (SELECT AVG(priceDifference) FROM MomentumTrades) AS avg_diff,
  (SELECT COUNT(*) FROM FeelingLuckyTrades) AS luck_cnt,
  (SELECT COUNT(*) FROM MomentumTrades) AS momo_cnt
"""

def main():
    client = bigquery.Client()
    print("Running BigQuery gold-equivalent SQL...")
    job = client.query(SQL)
    for row in job:
        print(dict(row))


if __name__ == "__main__":
    main()
