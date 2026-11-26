"""Load the historical CSV files into the database.

Usage: uv run python -m app.load_csv
"""

import csv
import logging
import os

from dotenv import load_dotenv

from app import ENV_FILE
from psycopg import sql

from app.db import connect, insert_rows
from app.models import MODELS

FILES = {
    "departments": "DEPARTMENTS_FILE",
    "jobs": "JOBS_FILE",
    "hired_employees": "HIRED_EMPLOYEES_FILE",
}

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("load_csv")


def read_csv(path, columns) -> list[dict]:
    # newline="" handles CRLF and a last row without a line break.
    # The files have no header. Empty fields become None.
    with open(path, newline="", encoding="utf-8") as handle:
        return [
            {column: value or None for column, value in zip(columns, values)}
            for values in csv.reader(handle)
        ]


def main() -> None:
    load_dotenv(ENV_FILE)
    with connect() as conn:
        for table, model in MODELS.items():
            # The initial load runs only once.
            exists = sql.SQL("SELECT EXISTS (SELECT 1 FROM {})").format(sql.Identifier(table))
            result = conn.execute(exists).fetchone()
            if result and result[0]:
                raise SystemExit(f"Table {table} is not empty. The initial load runs only once.")

            rows = read_csv(os.environ[FILES[table]], list(model.model_fields))
            inserted, rejected = insert_rows(conn, table, "csv", rows)
            conn.commit()
            log.info("%s: %d read, %d inserted, %d rejected", table, len(rows), inserted, rejected)


if __name__ == "__main__":
    main()
