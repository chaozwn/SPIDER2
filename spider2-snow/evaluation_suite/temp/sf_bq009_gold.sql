EXECUTE IMMEDIATE $$
DECLARE
  union_sql STRING;
  final_sql STRING;
BEGIN
  SELECT LISTAGG(
    'SELECT "date", "trafficSource", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."' || table_name || '"',
    ' UNION ALL '
  ) WITHIN GROUP (ORDER BY table_name)
  INTO :union_sql
  FROM "GA360".INFORMATION_SCHEMA.TABLES
  WHERE table_schema = 'GOOGLE_ANALYTICS_SAMPLE'
    AND table_name BETWEEN 'GA_SESSIONS_20170101' AND 'GA_SESSIONS_20170801';

  final_sql := '
    WITH sessions_2017 AS (
      ' || union_sql || '
    ),
    monthly_revenue AS (
      SELECT
        TO_CHAR(TO_DATE("date", ''YYYYMMDD''), ''YYYYMM'') AS month,
        "trafficSource":"source"::string AS traffic_source,
        ROUND(SUM(COALESCE("totals":"totalTransactionRevenue"::number, 0)) / 1000000, 2) AS revenue
      FROM sessions_2017
      GROUP BY 1, 2
    ),
    top_source AS (
      SELECT traffic_source
      FROM monthly_revenue
      GROUP BY traffic_source
      ORDER BY SUM(revenue) DESC
      LIMIT 1
    )
    SELECT
      m.traffic_source AS "TRAFFIC_SOURCE",
      ROUND(MAX(m.revenue) - MIN(m.revenue), 2) AS "REVENUE_DIFFERENCE"
    FROM monthly_revenue m
    JOIN top_source t
      ON m.traffic_source = t.traffic_source
    GROUP BY m.traffic_source
  ';

  EXECUTE IMMEDIATE final_sql;
END;
$$;