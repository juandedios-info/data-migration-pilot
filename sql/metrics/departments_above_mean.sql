-- Departments that hired more employees in 2021 than the mean of all departments.
-- LEFT JOIN with the date filter in ON: a department with no hires counts as 0.
WITH hires_2021 AS (
    SELECT d.id, d.department, COUNT(h.id) AS hired
    FROM departments d
    LEFT JOIN hired_employees h
           ON h.department_id = d.id
          AND h.datetime >= TIMESTAMPTZ '2021-01-01 00:00:00+00'
          AND h.datetime <  TIMESTAMPTZ '2022-01-01 00:00:00+00'
    GROUP BY d.id, d.department
)
SELECT id, department, hired
FROM hires_2021
WHERE hired > (SELECT AVG(hired) FROM hires_2021)
ORDER BY hired DESC
