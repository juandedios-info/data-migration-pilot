-- Step 2. Is every field present?
-- The data rules say that all fields are required.
-- A field can be missing in two ways: as NULL, or as blank text (only spaces).
-- This query counts both, for every column of every table.

SELECT 'hired_employees' AS table_name, 'id' AS column_name,
       COUNT(*) FILTER (WHERE id IS NULL) AS null_values,
       COUNT(*) FILTER (WHERE TRIM(id) = '') AS blank_values
FROM hired_employees_raw
UNION ALL SELECT 'hired_employees', 'name',
       COUNT(*) FILTER (WHERE name IS NULL), COUNT(*) FILTER (WHERE TRIM(name) = '')
FROM hired_employees_raw
UNION ALL SELECT 'hired_employees', 'datetime',
       COUNT(*) FILTER (WHERE datetime IS NULL), COUNT(*) FILTER (WHERE TRIM(datetime) = '')
FROM hired_employees_raw
UNION ALL SELECT 'hired_employees', 'department_id',
       COUNT(*) FILTER (WHERE department_id IS NULL), COUNT(*) FILTER (WHERE TRIM(department_id) = '')
FROM hired_employees_raw
UNION ALL SELECT 'hired_employees', 'job_id',
       COUNT(*) FILTER (WHERE job_id IS NULL), COUNT(*) FILTER (WHERE TRIM(job_id) = '')
FROM hired_employees_raw
UNION ALL SELECT 'departments', 'id',
       COUNT(*) FILTER (WHERE id IS NULL), COUNT(*) FILTER (WHERE TRIM(id) = '')
FROM departments_raw
UNION ALL SELECT 'departments', 'department',
       COUNT(*) FILTER (WHERE department IS NULL), COUNT(*) FILTER (WHERE TRIM(department) = '')
FROM departments_raw
UNION ALL SELECT 'jobs', 'id',
       COUNT(*) FILTER (WHERE id IS NULL), COUNT(*) FILTER (WHERE TRIM(id) = '')
FROM jobs_raw
UNION ALL SELECT 'jobs', 'job',
       COUNT(*) FILTER (WHERE job IS NULL), COUNT(*) FILTER (WHERE TRIM(job) = '')
FROM jobs_raw;

-- Rows with at least one missing field. These rows break the data rules:
-- the loader will not insert them, it will log them as rejected.
-- The query above found no blank values, so here we only check for NULL.
SELECT 'hired_employees' AS table_name,
       COUNT(*) FILTER (WHERE id IS NULL OR name IS NULL OR datetime IS NULL
                        OR department_id IS NULL OR job_id IS NULL) AS incomplete_rows
FROM hired_employees_raw
UNION ALL SELECT 'departments', COUNT(*) FILTER (WHERE id IS NULL OR department IS NULL)
FROM departments_raw
UNION ALL SELECT 'jobs', COUNT(*) FILTER (WHERE id IS NULL OR job IS NULL)
FROM jobs_raw;
