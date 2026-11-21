-- Step 7. Are there repeated records that the keys cannot see?
-- The ids are unique (step 4), so no row is an exact copy of another.
-- But the same person could appear twice with different ids. Here we look
-- for rows with the same name and the same hire date and time.
-- The subquery finds the repeated name and datetime pairs. The JOIN brings
-- back the full rows, so the cases can be reviewed and not only counted.

SELECT h.id, h.name, h.datetime, h.department_id, h.job_id
FROM hired_employees_raw h
JOIN (
    SELECT name, datetime
    FROM hired_employees_raw
    WHERE name IS NOT NULL AND datetime IS NOT NULL
    GROUP BY name, datetime
    HAVING COUNT(*) > 1
) d ON h.name = d.name AND h.datetime = d.datetime
ORDER BY h.name, TRY_CAST(h.id AS INTEGER);
