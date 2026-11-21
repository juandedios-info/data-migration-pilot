-- Step 1. What did we receive?
-- File integrity is checked outside SQL, with one command:
--   shasum -a 256 -c docs/raw_data.sha256

-- 1a. File format.
-- Each file is read as one block of text. For each file we count the
-- carriage returns (\r) and the line feeds (\n), check if it ends with a
-- line break, and show the first line to see if it is a header or data.
-- Count trick: length of the text minus length of the text without \r = number of \r.
SELECT filename,
       length(decode(content)) - length(replace(decode(content), chr(13), '')) AS carriage_returns,
       length(decode(content)) - length(replace(decode(content), chr(10), '')) AS line_feeds,
       ends_with(decode(content), chr(10)) AS ends_with_line_break,
       split_part(decode(content), chr(13) || chr(10), 1) AS first_line
FROM read_blob([getenv('HIRED_EMPLOYEES_FILE'),
                getenv('DEPARTMENTS_FILE'),
                getenv('JOBS_FILE')]);

-- 1b. Number of rows in each file, read with a real CSV parser.
-- `wc -l` counts one row less for departments and jobs, because their last
-- row has no line break.
-- After the load, the row counts in the database must match these numbers.
SELECT 'hired_employees' AS table_name, COUNT(*) AS row_count FROM hired_employees_raw
UNION ALL SELECT 'departments', COUNT(*) FROM departments_raw
UNION ALL SELECT 'jobs', COUNT(*) FROM jobs_raw;
