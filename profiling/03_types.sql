-- Step 3. Can the values be stored with the right types?
-- The data dictionary defines the ids as INTEGER and datetime as a STRING
-- in ISO format. We test if the ids are valid integers, and if the datetime
-- strings can be stored as a timestamp type (TIMESTAMPTZ).
-- We only test the values that are not NULL (missing values were counted in step 2).
-- TRY_CAST tries to convert a value. If the conversion fails, it returns NULL
-- instead of an error, so we can count the values that cannot be converted.

SELECT 'hired_employees' AS table_name, 'id' AS column_name,
       'INTEGER' AS dictionary_type, 'INTEGER' AS target_type,
       COUNT(id) AS non_null_values,
       COUNT(*) FILTER (WHERE id IS NOT NULL AND TRY_CAST(id AS INTEGER) IS NULL) AS failed_conversions
FROM hired_employees_raw
UNION ALL SELECT 'hired_employees', 'datetime', 'STRING (ISO format)', 'TIMESTAMPTZ',
       COUNT(datetime),
       COUNT(*) FILTER (WHERE datetime IS NOT NULL AND TRY_CAST(datetime AS TIMESTAMPTZ) IS NULL)
FROM hired_employees_raw
UNION ALL SELECT 'hired_employees', 'department_id', 'INTEGER', 'INTEGER',
       COUNT(department_id),
       COUNT(*) FILTER (WHERE department_id IS NOT NULL AND TRY_CAST(department_id AS INTEGER) IS NULL)
FROM hired_employees_raw
UNION ALL SELECT 'hired_employees', 'job_id', 'INTEGER', 'INTEGER',
       COUNT(job_id),
       COUNT(*) FILTER (WHERE job_id IS NOT NULL AND TRY_CAST(job_id AS INTEGER) IS NULL)
FROM hired_employees_raw
UNION ALL SELECT 'departments', 'id', 'INTEGER', 'INTEGER',
       COUNT(id),
       COUNT(*) FILTER (WHERE id IS NOT NULL AND TRY_CAST(id AS INTEGER) IS NULL)
FROM departments_raw
UNION ALL SELECT 'jobs', 'id', 'INTEGER', 'INTEGER',
       COUNT(id),
       COUNT(*) FILTER (WHERE id IS NOT NULL AND TRY_CAST(id AS INTEGER) IS NULL)
FROM jobs_raw;

-- A valid date is not enough: we also check that all dates use exactly the
-- same format, for example 2021-11-07T02:48:42Z.
-- The final Z means the time is in UTC.
SELECT COUNT(datetime) AS non_null_values,
       COUNT(*) FILTER (WHERE datetime IS NOT NULL
                        AND NOT regexp_full_match(datetime, '\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z')) AS not_iso_utc
FROM hired_employees_raw;
