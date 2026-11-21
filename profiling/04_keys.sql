-- Step 4. Can every row be identified?
-- A primary key must be unique and never NULL.
-- For each table we compare the number of rows with the number of distinct
-- ids, and we count the NULL ids. If rows = distinct ids and there are no
-- NULL ids, the id can be the primary key.
-- Min and max show the range of the ids. The ids are text in the raw files,
-- so we convert them to INTEGER first: as text, '999' would be greater than '1999'.

SELECT 'hired_employees' AS table_name,
       COUNT(*) AS row_count,
       COUNT(DISTINCT id) AS distinct_ids,
       COUNT(*) FILTER (WHERE id IS NULL) AS null_ids,
       MIN(TRY_CAST(id AS INTEGER)) AS min_id,
       MAX(TRY_CAST(id AS INTEGER)) AS max_id
FROM hired_employees_raw
UNION ALL SELECT 'departments', COUNT(*), COUNT(DISTINCT id), COUNT(*) FILTER (WHERE id IS NULL),
       MIN(TRY_CAST(id AS INTEGER)), MAX(TRY_CAST(id AS INTEGER))
FROM departments_raw
UNION ALL SELECT 'jobs', COUNT(*), COUNT(DISTINCT id), COUNT(*) FILTER (WHERE id IS NULL),
       MIN(TRY_CAST(id AS INTEGER)), MAX(TRY_CAST(id AS INTEGER))
FROM jobs_raw;
