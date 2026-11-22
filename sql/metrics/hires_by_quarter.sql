-- Hires in 2021 per department and job, divided by quarter (UTC).
SELECT
    d.department,
    j.job,
    COUNT(*) FILTER (WHERE EXTRACT(QUARTER FROM h.datetime AT TIME ZONE 'UTC') = 1) AS "Q1",
    COUNT(*) FILTER (WHERE EXTRACT(QUARTER FROM h.datetime AT TIME ZONE 'UTC') = 2) AS "Q2",
    COUNT(*) FILTER (WHERE EXTRACT(QUARTER FROM h.datetime AT TIME ZONE 'UTC') = 3) AS "Q3",
    COUNT(*) FILTER (WHERE EXTRACT(QUARTER FROM h.datetime AT TIME ZONE 'UTC') = 4) AS "Q4"
FROM hired_employees h
JOIN departments d ON d.id = h.department_id
JOIN jobs j        ON j.id = h.job_id
WHERE h.datetime >= TIMESTAMPTZ '2021-01-01 00:00:00+00'
  AND h.datetime <  TIMESTAMPTZ '2022-01-01 00:00:00+00'
GROUP BY d.department, j.job
ORDER BY d.department, j.job
