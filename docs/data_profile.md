# Data Profile

Profiling the raw data gives a clear picture of its structure and helps prevent
common problems when moving data from an old system to a new one. The queries
for this report are in `profiling/` and run in the DuckDB CLI.

**Target database:** PostgreSQL. The challenge lets us choose any SQL database.
When a type is specific to PostgreSQL, the standard SQL name is also given.

## How to reproduce

Check that the raw files are unchanged:

```bash
set -a; source ~/.config/data-migration-pilot.env; set +a
(cd "$DATAWORK_DIR" && shasum -a 256 -c -) < docs/raw_data.sha256
```

Run the profiling queries:

```bash
duckdb
```

Then, inside DuckDB, run the files in order:

```sql
.read profiling/00_setup.sql
.read profiling/01_volume.sql
.read profiling/02_completeness.sql
.read profiling/03_types.sql
.read profiling/04_keys.sql
.read profiling/05_relationships.sql
.read profiling/06_text.sql
.read profiling/07_business_duplicates.sql
```

## Step 1. What did we receive?

### Integrity of the raw files

The checksums were saved in `docs/raw_data.sha256` when the files were
received. This command checks each file against them:

```bash
(cd "$DATAWORK_DIR" && shasum -a 256 -c -) < docs/raw_data.sha256
```

```text
raw/departments.csv: OK
raw/hired_employees (1).csv: OK
raw/jobs.csv: OK
```

The three files have not changed.

### File format

| file | carriage returns | line feeds | ends with line break | first line |
| --- | --- | --- | --- | --- |
| `hired_employees (1).csv` | 1,999 | 1,999 | yes | `1,Harold Vogt,2021-11-07T02:48:42Z,2,96` |
| `departments.csv` | 11 | 11 | no | `1,Product Management` |
| `jobs.csv` | 182 | 182 | no | `1,Marketing Assistant` |

What this shows:

- Every row has the expected number of comma-separated fields (5 in
  `hired_employees`, 2 in `departments` and `jobs`). DuckDB reads each file with
  these columns declared, and it would fail on a row with a different number
  of fields.
- The first line of each file is already data, so there is no header.
- Every line break is a carriage return plus a line feed (Windows line endings,
  CRLF): each file has the same number of carriage returns and line feeds.
- `departments.csv` and `jobs.csv` do not end with a line break. Tools that
  count line breaks, like `wc -l`, report one row less for these files.

### Volume

| table | rows |
| --- | --- |
| hired_employees | 1,999 |
| departments | 12 |
| jobs | 183 |

For `departments` and `jobs`, the row count is one more than the number of line
feeds, because the last row has no line break.

**Decision:** Load the files with a real CSV parser, not by splitting lines.
The parser must handle CRLF and a last row without a line break. After the
load, compare the row counts with this table.

## Step 2. Is every field present?

| table | column | null values | blank values |
| --- | --- | --- | --- |
| hired_employees | id | 0 | 0 |
| hired_employees | name | 19 | 0 |
| hired_employees | datetime | 14 | 0 |
| hired_employees | department_id | 21 | 0 |
| hired_employees | job_id | 16 | 0 |
| departments | id | 0 | 0 |
| departments | department | 0 | 0 |
| jobs | id | 0 | 0 |
| jobs | job | 0 | 0 |

| table | incomplete rows |
| --- | --- |
| hired_employees | 70 |
| departments | 0 |
| jobs | 0 |

There are no blank values, so an incomplete row is a row with at least one
`NULL`. `hired_employees` has 70 incomplete rows. The missing values per column
also add up to 70 (19 + 14 + 21 + 16), so each incomplete row is missing only
one field. `departments` and `jobs` are complete.

**Decision:** The data rules say that all fields are required, so these 70 rows
break the rules. The loader will not insert them; it will log them as
rejected. The other 1,929 rows will be inserted.

In the new tables, every column is `NOT NULL`. This is a second check: if a bad
row gets past the loader by mistake, the database blocks it. For text columns,
`NOT NULL` is not enough, because an empty string (`''`) is not `NULL`. Text
columns also get `CHECK (TRIM(column) <> '')`.

## Step 3. Can the values be stored with the right types?

The data dictionary defines the ids as `INTEGER` and `datetime` as a `STRING`
in ISO format. We test if the ids are valid integers, and if the datetime
strings can be stored as a timestamp type. Only non-null values are tested.
Missing values were counted in step 2.

| table | column | dictionary type | target type | non-null values | failed conversions |
| --- | --- | --- | --- | --- | --- |
| hired_employees | id | INTEGER | INTEGER | 1,999 | 0 |
| hired_employees | datetime | STRING (ISO format) | TIMESTAMPTZ | 1,985 | 0 |
| hired_employees | department_id | INTEGER | INTEGER | 1,978 | 0 |
| hired_employees | job_id | INTEGER | INTEGER | 1,983 | 0 |
| departments | id | INTEGER | INTEGER | 12 | 0 |
| jobs | id | INTEGER | INTEGER | 183 | 0 |

All 1,985 datetime values use the same ISO 8601 format in UTC (they end with
`Z`). For every column, the nulls (step 2) plus the non-null values (step 3)
add up to the row count (step 1), so every step checks the same rows.

**Decision:** Ids are `INTEGER`. `datetime` changes from text to `TIMESTAMPTZ`
(standard SQL: `TIMESTAMP WITH TIME ZONE`). All values use the same format in
UTC, so the conversion keeps the exact same moment in time and no information
is lost. A date type also makes it easy to filter by year and group by quarter,
which the second challenge needs.

## Step 4. Can every row be identified?

| table | rows | distinct ids | null ids | min id | max id |
| --- | --- | --- | --- | --- | --- |
| hired_employees | 1,999 | 1,999 | 0 | 1 | 1,999 |
| departments | 12 | 12 | 0 | 1 | 12 |
| jobs | 183 | 183 | 0 | 1 | 183 |

In every table, the id is unique and never null.

**Decision:** `id` is the primary key of each table. The ids come from the
source system, both in the CSV files and in the API requests. We keep them as
they are, so the database does not generate new ids (no `SERIAL` or `IDENTITY`).

A separate generated key (a surrogate key) is useful when data comes from
several systems, or when we keep a history of changes. This project has one
source, so it is not needed.

## Step 5. Do the tables fit together?

| orphan department ids | orphan job ids | departments used | jobs used |
| --- | --- | --- | --- |
| 0 | 0 | 12 | 172 |

| table | ids never used by a hire |
| --- | --- |
| departments | 0 |
| jobs | 11 |

Every non-null `department_id` and `job_id` exists in its table. All 12
departments have hires. 11 of the 183 jobs have no hires (183 − 172 = 11).

**Decision:** Add foreign keys from `hired_employees.department_id` to
`departments.id`, and from `hired_employees.job_id` to `jobs.id`. The historical
data already follows them. This means:

- Load `departments` and `jobs` first, then `hired_employees`.
- If the API receives a row with a department or job that does not exist, the
  database rejects it, and the row is logged as rejected.
- The 11 unused jobs are kept. They just have no hires.

## Step 6. Is the text clean?

| table | column | max length | surrounding spaces | tabs or line breaks |
| --- | --- | --- | --- | --- |
| hired_employees | name | 29 | 0 | 0 |
| departments | department | 24 | 0 | 0 |
| jobs | job | 36 | 0 | 0 |

No value has spaces at the start or the end, and no value contains tabs or
line breaks. These characters are invisible, but they break comparisons and
joins (`'Sales\r'` is not equal to `'Sales'`). The carriage returns from the
CRLF line endings did not get into the data.

**Decision:** Text columns are `TEXT` in PostgreSQL. `TEXT` has no length limit
and is as fast as `VARCHAR`. In other databases, the equivalent is `VARCHAR`
with a generous limit. The historical data is clean. But the example in the
data dictionary (`1, Supply Chain`) has a space after the comma, so the API
will remove spaces at the start and the end of text values before checking them.

## Step 7. Are there repeated records that the keys cannot see?

| id | name | datetime | department_id | job_id |
| --- | --- | --- | --- | --- |
| 470 | Lianne Huxton | 2021-02-08T00:15:19Z | 7 | 94 |
| 1470 | Lianne Huxton | 2021-02-08T00:15:19Z | 5 | 74 |

The same name appears twice with the same hire date and time, but with
different ids, departments and jobs. The data cannot tell if these are two
people with the same name or a duplicated record. The data rules do not say
anything about this case, and both rows follow all the rules.

**Decision:** Do not add a `UNIQUE (name, datetime)` constraint, because it
could reject a valid record. Both rows are loaded, and the case is reported
here so the data owners can review it.

## Summary of schema decisions

| decision | step |
| --- | --- |
| The loader uses a CSV parser that handles CRLF and a last row without a line break | 1 |
| Rows with missing fields are not inserted; they are logged as rejected | 2 |
| After the load: 1,929 rows inserted and 70 rejected, compared with the profile | 1 and 2 |
| Every column is `NOT NULL`; text columns also have `CHECK (TRIM(column) <> '')` | 2 |
| Ids are `INTEGER`; `datetime` changes from text to `TIMESTAMPTZ` | 3 |
| `id` is the primary key, and the ids from the source are kept | 4 |
| Foreign keys to `departments` and `jobs`; load these tables first | 5 |
| Text columns are `TEXT`; the API trims text values | 6 |
| No unique constraint on name and datetime | 7 |
