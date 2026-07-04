WITH bad_series AS (
    SELECT DISTINCT
        da."SeriesInstanceUID"
    FROM "IDC"."IDC_V17"."DICOM_ALL" da
    WHERE da."SeriesInstanceUID" IS NOT NULL
      AND (
          da."TransferSyntaxUID" IN (
              '1.2.840.10008.1.2.4.70',
              '1.2.840.10008.1.2.4.51'
          )
          OR UPPER(TO_VARCHAR(da."ImageType")) LIKE '%LOCALIZER%'
      )
),
filtered AS (
    SELECT
        da."SeriesInstanceUID",
        da."StudyInstanceUID",
        da."SeriesNumber",
        da."PatientID",
        da."SOPInstanceUID",
        da."SliceThickness",
        da."instance_size",
        TRY_TO_DOUBLE(da."Exposure"::STRING) AS "exposure",
        TRY_TO_DOUBLE(da."ImagePositionPatient"[2]::STRING) AS "pos_z",
        TO_VARCHAR(da."ImagePositionPatient") AS "position_raw",
        CONCAT(
            TO_VARCHAR(da."ImagePositionPatient"[0]),
            '/',
            TO_VARCHAR(da."ImagePositionPatient"[1])
        ) AS "xy_position_raw",
        TO_VARCHAR(da."ImageOrientationPatient") AS "orientation_raw",
        TO_VARCHAR(da."PixelSpacing") AS "pixel_spacing_raw",
        da."Rows",
        da."Columns",
        TRY_TO_DOUBLE(da."ImageOrientationPatient"[0]::STRING)
          * TRY_TO_DOUBLE(da."ImageOrientationPatient"[4]::STRING)
        - TRY_TO_DOUBLE(da."ImageOrientationPatient"[1]::STRING)
          * TRY_TO_DOUBLE(da."ImageOrientationPatient"[3]::STRING) AS "cross_z"
    FROM "IDC"."IDC_V17"."DICOM_ALL" da
    WHERE COALESCE(LOWER(da."collection_id"), '') != 'nlst'
      AND COALESCE(UPPER(da."collection_name"), '') != 'NLST'
      AND da."Modality" = 'CT'
      AND da."SeriesInstanceUID" IS NOT NULL
      AND da."SOPInstanceUID" IS NOT NULL
      AND da."PatientID" IS NOT NULL
      AND da."ImagePositionPatient" IS NOT NULL
      AND da."ImageOrientationPatient" IS NOT NULL
      AND da."PixelSpacing" IS NOT NULL
      AND NOT EXISTS (
          SELECT 1
          FROM bad_series bs
          WHERE bs."SeriesInstanceUID" = da."SeriesInstanceUID"
      )
      AND TRY_TO_DOUBLE(da."ImagePositionPatient"[0]::STRING) IS NOT NULL
      AND TRY_TO_DOUBLE(da."ImagePositionPatient"[1]::STRING) IS NOT NULL
      AND TRY_TO_DOUBLE(da."ImagePositionPatient"[2]::STRING) IS NOT NULL
      AND TRY_TO_DOUBLE(da."PixelSpacing"[0]::STRING) IS NOT NULL
      AND TRY_TO_DOUBLE(da."PixelSpacing"[1]::STRING) IS NOT NULL
      AND TRY_TO_DOUBLE(da."ImageOrientationPatient"[0]::STRING) IS NOT NULL
      AND TRY_TO_DOUBLE(da."ImageOrientationPatient"[1]::STRING) IS NOT NULL
      AND TRY_TO_DOUBLE(da."ImageOrientationPatient"[2]::STRING) IS NOT NULL
      AND TRY_TO_DOUBLE(da."ImageOrientationPatient"[3]::STRING) IS NOT NULL
      AND TRY_TO_DOUBLE(da."ImageOrientationPatient"[4]::STRING) IS NOT NULL
      AND TRY_TO_DOUBLE(da."ImageOrientationPatient"[5]::STRING) IS NOT NULL
),
with_intervals AS (
    SELECT
        f.*,
        LEAD(f."pos_z") OVER (
            PARTITION BY f."SeriesInstanceUID"
            ORDER BY f."pos_z"
        ) - f."pos_z" AS "z_diff"
    FROM filtered f
),
series_metrics AS (
    SELECT
        wd."SeriesInstanceUID",
        MIN(wd."SeriesNumber") AS "SeriesNumber",
        MIN(wd."StudyInstanceUID") AS "StudyInstanceUID",
        MIN(wd."PatientID") AS "PatientID",
        COUNT(DISTINCT wd."SOPInstanceUID") AS "sop_instance_count",
        COUNT(DISTINCT wd."position_raw") AS "position_count",
        COUNT(DISTINCT wd."xy_position_raw") AS "xy_position_count",
        COUNT(DISTINCT wd."orientation_raw") AS "orientation_count",
        COUNT(DISTINCT wd."pixel_spacing_raw") AS "pixel_spacing_count",
        COUNT(DISTINCT wd."Rows") AS "rows_count",
        COUNT(DISTINCT wd."Columns") AS "cols_count",
        COUNT(DISTINCT wd."SliceThickness") AS "distinct_slice_thickness",
        MAX(wd."cross_z") AS "max_cross_z",
        MIN(wd."cross_z") AS "min_cross_z",
        MAX(wd."z_diff") AS "max_slice_interval_diff",
        MIN(wd."z_diff") AS "min_slice_interval_diff",
        COALESCE(MAX(wd."z_diff") - MIN(wd."z_diff"), 0) AS "slice_interval_tolerance",
        COUNT(DISTINCT wd."exposure") AS "distinct_exposure_values",
        MAX(wd."exposure") AS "max_exposure",
        MIN(wd."exposure") AS "min_exposure",
        MAX(wd."exposure") - MIN(wd."exposure") AS "exposure_range",
        SUM(COALESCE(wd."instance_size", 0)) / 1048576.0 AS "series_size_mib"
    FROM with_intervals wd
    GROUP BY wd."SeriesInstanceUID"
)
SELECT
    sm."SeriesInstanceUID" AS "SERIES_INSTANCE_UID",
    sm."SeriesNumber" AS "SERIES_NUMBER",
    sm."StudyInstanceUID" AS "STUDY_INSTANCE_UID",
    sm."PatientID" AS "PATIENT_ID",
    GREATEST(ABS(sm."max_cross_z"), ABS(sm."min_cross_z")) AS "MAX_DOT_PRODUCT",
    sm."sop_instance_count" AS "SOP_INSTANCE_COUNT",
    sm."distinct_slice_thickness" AS "DISTINCT_SLICE_THICKNESS_VALUES",
    sm."max_slice_interval_diff" AS "MAX_SLICE_INTERVAL_DIFF",
    sm."min_slice_interval_diff" AS "MIN_SLICE_INTERVAL_DIFF",
    sm."slice_interval_tolerance" AS "SLICE_INTERVAL_TOLERANCE",
    sm."distinct_exposure_values" AS "DISTINCT_EXPOSURE_VALUES",
    sm."max_exposure" AS "MAX_EXPOSURE",
    sm."min_exposure" AS "MIN_EXPOSURE",
    sm."exposure_range" AS "EXPOSURE_RANGE",
    sm."series_size_mib" AS "SERIES_SIZE_MIB"
FROM series_metrics sm
WHERE sm."sop_instance_count" = sm."position_count"
  AND sm."xy_position_count" = 1
  AND sm."orientation_count" = 1
  AND sm."pixel_spacing_count" = 1
  AND sm."rows_count" = 1
  AND sm."cols_count" = 1
  AND ABS(sm."min_cross_z") BETWEEN 0.99 AND 1.01
  AND ABS(sm."max_cross_z") BETWEEN 0.99 AND 1.01
  AND sm."slice_interval_tolerance" < 0.01
ORDER BY
    sm."slice_interval_tolerance" DESC,
    sm."exposure_range" DESC NULLS LAST,
    sm."SeriesInstanceUID" DESC;
