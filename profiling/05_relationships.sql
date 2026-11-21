-- Step 5. Do the tables fit together?
-- Every department_id and job_id in hired_employees must exist in its table
-- (departments or jobs). We only check the values that are not NULL
-- (missing values were counted in step 2).
-- With a LEFT JOIN, a hire whose id is not found in the other table gets
-- NULL on the right side. That id is an orphan: it points to nothing.

SELECT
    COUNT(*) FILTER (WHERE h.department_id IS NOT NULL AND d.id IS NULL) AS orphan_department_ids,
    COUNT(*) FILTER (WHERE h.job_id IS NOT NULL AND j.id IS NULL)        AS orphan_job_ids,
    COUNT(DISTINCT h.department_id) AS departments_used,
    COUNT(DISTINCT h.job_id)        AS jobs_used
FROM hired_employees_raw h
LEFT JOIN departments_raw d ON h.department_id = d.id
LEFT JOIN jobs_raw j        ON h.job_id = j.id;

-- Departments and jobs that no hire uses.
-- NOT EXISTS keeps a row only when no hire has its id.
SELECT 'departments' AS table_name, COUNT(*) AS unused_ids
FROM departments_raw d
WHERE NOT EXISTS (SELECT 1 FROM hired_employees_raw h WHERE h.department_id = d.id)
UNION ALL
SELECT 'jobs', COUNT(*)
FROM jobs_raw j
WHERE NOT EXISTS (SELECT 1 FROM hired_employees_raw h WHERE h.job_id = j.id);
