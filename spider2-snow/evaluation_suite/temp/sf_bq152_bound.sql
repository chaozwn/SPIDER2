WITH copy AS (
  SELECT "case_barcode", "chromosome", "start_pos", "end_pos", MAX("copy_number") AS "copy_number"
  FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
  WHERE "project_short_name" = 'TCGA-BRCA'
  GROUP BY "case_barcode", "chromosome", "start_pos", "end_pos"
),
total AS (
  SELECT COUNT(DISTINCT "case_barcode") AS t FROM copy
),
cytob AS (
  SELECT "chromosome", "cytoband_name", "hg38_start", "hg38_stop"
  FROM "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38"
  WHERE "cytoband_name" = '1p33'
),
joined AS (
  SELECT
    copy."case_barcode",
    (
      ABS(cytob."hg38_stop" - cytob."hg38_start") + ABS(copy."end_pos" - copy."start_pos")
      - ABS(cytob."hg38_stop" - copy."end_pos") - ABS(cytob."hg38_start" - copy."start_pos")
    ) / 2.0 AS "overlap",
    copy."copy_number"
  FROM copy
  JOIN cytob ON cytob."chromosome" = copy."chromosome"
  WHERE (cytob."hg38_start" >= copy."start_pos" AND copy."end_pos" >= cytob."hg38_start")
     OR (copy."start_pos" >= cytob."hg38_start" AND copy."start_pos" <= cytob."hg38_stop")
),
w AS (
  SELECT
    "case_barcode",
    SUM("overlap" * "copy_number") / SUM("overlap") AS "wavg",
    ROUND(SUM("overlap" * "copy_number") / SUM("overlap")) AS "cn_round",
    FLOOR(SUM("overlap" * "copy_number") / SUM("overlap") + 0.5) AS "cn_floor5",
    ROUND(SUM("overlap" * "copy_number") / SUM("overlap"), 0, 'HALF_TO_EVEN') AS "cn_even"
  FROM joined
  GROUP BY "case_barcode"
)
SELECT
  'round' AS k,
  SUM(IFF("cn_round" = 2, 1, 0)) AS n2,
  SUM(IFF("cn_round" = 3, 1, 0)) AS g3,
  ROUND(100.0 * SUM(IFF("cn_round" = 2, 1, 0)) / MAX(t), 2) AS pct2,
  ROUND(100.0 * SUM(IFF("cn_round" = 3, 1, 0)) / MAX(t), 2) AS pct3
FROM w, total
UNION ALL
SELECT
  'floor5',
  SUM(IFF("cn_floor5" = 2, 1, 0)),
  SUM(IFF("cn_floor5" = 3, 1, 0)),
  ROUND(100.0 * SUM(IFF("cn_floor5" = 2, 1, 0)) / MAX(t), 2),
  ROUND(100.0 * SUM(IFF("cn_floor5" = 3, 1, 0)) / MAX(t), 2)
FROM w, total
UNION ALL
SELECT
  'even',
  SUM(IFF("cn_even" = 2, 1, 0)),
  SUM(IFF("cn_even" = 3, 1, 0)),
  ROUND(100.0 * SUM(IFF("cn_even" = 2, 1, 0)) / MAX(t), 2),
  ROUND(100.0 * SUM(IFF("cn_even" = 3, 1, 0)) / MAX(t), 2)
FROM w, total;

-- near-half cases
WITH copy AS (
  SELECT "case_barcode", "chromosome", "start_pos", "end_pos", MAX("copy_number") AS "copy_number"
  FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
  WHERE "project_short_name" = 'TCGA-BRCA'
  GROUP BY "case_barcode", "chromosome", "start_pos", "end_pos"
),
cytob AS (
  SELECT "chromosome", "cytoband_name", "hg38_start", "hg38_stop"
  FROM "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38"
  WHERE "cytoband_name" = '1p33'
),
joined AS (
  SELECT
    copy."case_barcode",
    (
      ABS(cytob."hg38_stop" - cytob."hg38_start") + ABS(copy."end_pos" - copy."start_pos")
      - ABS(cytob."hg38_stop" - copy."end_pos") - ABS(cytob."hg38_start" - copy."start_pos")
    ) / 2.0 AS "overlap",
    copy."copy_number"
  FROM copy
  JOIN cytob ON cytob."chromosome" = copy."chromosome"
  WHERE (cytob."hg38_start" >= copy."start_pos" AND copy."end_pos" >= cytob."hg38_start")
     OR (copy."start_pos" >= cytob."hg38_start" AND copy."start_pos" <= cytob."hg38_stop")
),
w AS (
  SELECT
    "case_barcode",
    SUM("overlap" * "copy_number") / SUM("overlap") AS "wavg",
    ROUND(SUM("overlap" * "copy_number") / SUM("overlap")) AS "cn_round",
    FLOOR(SUM("overlap" * "copy_number") / SUM("overlap") + 0.5) AS "cn_floor5"
  FROM joined
  GROUP BY "case_barcode"
)
SELECT *
FROM w
WHERE ABS("wavg" - ROUND("wavg")) > 0.49
   OR ABS("wavg" - 2.5) < 0.02
   OR ABS("wavg" - 1.5) < 0.02
   OR ABS("wavg" - 3.5) < 0.02
   OR "cn_round" != "cn_floor5"
ORDER BY "wavg";
