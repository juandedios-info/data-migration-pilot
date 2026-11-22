-- Database schema. departments and jobs go first because hired_employees
-- references them. CREATE TABLE IF NOT EXISTS makes the script safe to rerun.

CREATE TABLE IF NOT EXISTS departments (
    id         INTEGER,
    department TEXT NOT NULL,
    CONSTRAINT pk_departments PRIMARY KEY (id),
    CONSTRAINT ck_departments_department_not_blank CHECK (TRIM(department) <> '')
);

CREATE TABLE IF NOT EXISTS jobs (
    id  INTEGER,
    job TEXT NOT NULL,
    CONSTRAINT pk_jobs PRIMARY KEY (id),
    CONSTRAINT ck_jobs_job_not_blank CHECK (TRIM(job) <> '')
);

-- No ON DELETE CASCADE: deleting a department or job with hires must fail.
CREATE TABLE IF NOT EXISTS hired_employees (
    id            INTEGER,
    name          TEXT        NOT NULL,
    datetime      TIMESTAMPTZ NOT NULL,
    department_id INTEGER     NOT NULL,
    job_id        INTEGER     NOT NULL,
    CONSTRAINT pk_hired_employees PRIMARY KEY (id),
    CONSTRAINT ck_hired_employees_name_not_blank CHECK (TRIM(name) <> ''),
    CONSTRAINT fk_hired_employees_department
        FOREIGN KEY (department_id) REFERENCES departments (id),
    CONSTRAINT fk_hired_employees_job
        FOREIGN KEY (job_id) REFERENCES jobs (id)
);

-- Rows that break the data rules, stored as they arrived.
-- row_data is JSONB because invalid values may not fit typed columns.
-- The id is generated here: rejections do not come from the source system.
CREATE TABLE IF NOT EXISTS rejected_rows (
    id          BIGINT GENERATED ALWAYS AS IDENTITY,
    table_name  TEXT        NOT NULL,
    source      TEXT        NOT NULL,
    row_data    JSONB       NOT NULL,
    reason      TEXT        NOT NULL,
    error_code  TEXT,
    rejected_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT pk_rejected_rows PRIMARY KEY (id),
    CONSTRAINT ck_rejected_rows_table_name
        CHECK (table_name IN ('hired_employees', 'departments', 'jobs')),
    CONSTRAINT ck_rejected_rows_source CHECK (source IN ('csv', 'api'))
);
