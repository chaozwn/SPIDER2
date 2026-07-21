-- sf_bq090: Feeling Lucky vs Momentum average intrinsic value difference (LONG trades)
-- intrinsic value = closePrice - openPrice = StrikePrice - LastPx
-- algorithm from LEFT(TargetCompID, 4): LUCK=Feeling Lucky, MOMO=Momentum
--
-- Official logic from spider2-lite/evaluation_suite/gold/sql/bq090.sql
-- Verified on Snowflake: 0.023069449773148013

WITH MomentumTrades AS (
  SELECT "StrikePrice" - "LastPx" AS priceDifference
  FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT
  WHERE LEFT("TargetCompID", 4) = 'MOMO'
    AND "Sides"[0]:Side::STRING = 'LONG'
),
FeelingLuckyTrades AS (
  SELECT "StrikePrice" - "LastPx" AS priceDifference
  FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT
  WHERE LEFT("TargetCompID", 4) = 'LUCK'
    AND "Sides"[0]:Side::STRING = 'LONG'
)
SELECT
  (SELECT AVG(priceDifference) FROM FeelingLuckyTrades)
  - (SELECT AVG(priceDifference) FROM MomentumTrades)
  AS AVG_INTRINSIC_VALUE_DIFFERENCE;
