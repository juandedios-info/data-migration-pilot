-- Step 6. Is the text clean?
-- For each text column we check three things:
--   max_length:          the longest value
--   surrounding_spaces:  values with spaces at the start or the end
--                        (TRIM removes them, so the value changes)
--   tabs_or_line_breaks: values that contain a tab (\t), a carriage
--                        return (\r) or a line feed (\n)
-- These characters are invisible, but they break comparisons and joins.
-- The example in the data dictionary ("1, Supply Chain") has a space after
-- the comma, so spaces are worth checking.

SELECT 'hired_employees' AS table_name, 'name' AS column_name,
       MAX(LENGTH(name)) AS max_length,
       COUNT(*) FILTER (WHERE name <> TRIM(name)) AS surrounding_spaces,
       COUNT(*) FILTER (WHERE regexp_matches(name, '[\t\r\n]')) AS tabs_or_line_breaks
FROM hired_employees_raw
UNION ALL SELECT 'departments', 'department',
       MAX(LENGTH(department)),
       COUNT(*) FILTER (WHERE department <> TRIM(department)),
       COUNT(*) FILTER (WHERE regexp_matches(department, '[\t\r\n]'))
FROM departments_raw
UNION ALL SELECT 'jobs', 'job',
       MAX(LENGTH(job)),
       COUNT(*) FILTER (WHERE job <> TRIM(job)),
       COUNT(*) FILTER (WHERE regexp_matches(job, '[\t\r\n]'))
FROM jobs_raw;
