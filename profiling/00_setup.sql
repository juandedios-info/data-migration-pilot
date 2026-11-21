-- Setup: create one view for each raw CSV file.
-- The file paths come from the .env file, not from the code.
-- All columns are read as text (VARCHAR), so we can see the raw values
-- before converting them to other types.
-- The files have no header, so the column names come from the data dictionary.

CREATE OR REPLACE VIEW hired_employees_raw AS
SELECT * FROM read_csv(getenv('HIRED_EMPLOYEES_FILE'),
    header = false,
    columns = {'id': 'VARCHAR', 'name': 'VARCHAR', 'datetime': 'VARCHAR',
               'department_id': 'VARCHAR', 'job_id': 'VARCHAR'});

CREATE OR REPLACE VIEW departments_raw AS
SELECT * FROM read_csv(getenv('DEPARTMENTS_FILE'),
    header = false,
    columns = {'id': 'VARCHAR', 'department': 'VARCHAR'});

CREATE OR REPLACE VIEW jobs_raw AS
SELECT * FROM read_csv(getenv('JOBS_FILE'),
    header = false,
    columns = {'id': 'VARCHAR', 'job': 'VARCHAR'});
