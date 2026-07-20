WITH copy AS (
  SELECT
    "case_barcode",
    "chromosome",
    "start_pos",
    "end_pos",
    MAX("copy_number") AS "copy_number"
  FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
  WHERE "project_short_name" = 'TCGA-BRCA'
  GROUP BY "case_barcode", "chromosome", "start_pos", "end_pos"
),
total_cases AS (
  SELECT COUNT(DISTINCT "case_barcode") AS "total" FROM copy
),
cytob AS (
  SELECT "chromosome", "cytoband_name", "hg38_start", "hg38_stop"
  FROM "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38"
),
joined AS (
  SELECT
    cytob."chromosome",
    cytob."cytoband_name",
    cytob."hg38_start",
    cytob."hg38_stop",
    copy."case_barcode",
    GREATEST(
      0.0,
      LEAST(copy."end_pos"::FLOAT, cytob."hg38_stop"::FLOAT)
        - GREATEST(copy."start_pos"::FLOAT, cytob."hg38_start"::FLOAT)
    ) AS "overlap",
    copy."copy_number"::FLOAT AS "copy_number"
  FROM copy
  JOIN cytob ON cytob."chromosome" = copy."chromosome"
  WHERE LEAST(copy."end_pos", cytob."hg38_stop") > GREATEST(copy."start_pos", cytob."hg38_start")
),
cbands AS (
  SELECT
    "chromosome", "cytoband_name", "hg38_start", "hg38_stop", "case_barcode",
    ROUND(SUM("overlap" * "copy_number") / NULLIF(SUM("overlap"), 0)) AS "copy_number"
  FROM joined
  GROUP BY "chromosome", "cytoband_name", "hg38_start", "hg38_stop", "case_barcode"
),
aberrations AS (
  SELECT
    "chromosome", "cytoband_name", "hg38_start", "hg38_stop",
    SUM(IFF("copy_number" = 0, 1, 0)) AS "total_homodel",
    SUM(IFF("copy_number" = 1, 1, 0)) AS "total_heterodel",
    SUM(IFF("copy_number" = 2, 1, 0)) AS "total_normal",
    SUM(IFF("copy_number" = 3, 1, 0)) AS "total_gain",
    SUM(IFF("copy_number" > 3, 1, 0)) AS "total_amp"
  FROM cbands
  GROUP BY "chromosome", "cytoband_name", "hg38_start", "hg38_stop"
)
SELECT
  a."cytoband_name",
  a."hg38_start",
  a."hg38_stop",
  ROUND(100.0 * a."total_homodel" / t."total", 2) AS "homozygous_deletion_frequency",
  ROUND(100.0 * a."total_heterodel" / t."total", 2) AS "heterozygous_deletion_frequency",
  ROUND(100.0 * a."total_normal" / t."total", 2) AS "normal_frequency",
  ROUND(100.0 * a."total_gain" / t."total", 2) AS "gain_frequency",
  ROUND(100.0 * a."total_amp" / t."total", 2) AS "amplification_frequency"
FROM aberrations a
CROSS JOIN total_cases t
ORDER BY a."chromosome", a."hg38_start", a."hg38_stop";
