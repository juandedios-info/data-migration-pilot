"""Back up a table to an AVRO file, and restore a table from a backup.

Usage:
    uv run python -m app.backup backup departments
    uv run python -m app.backup restore departments backups/departments_20261122T100000Z.avro
"""

import os
import sys
from datetime import datetime, timezone
from pathlib import Path

import psycopg
from dotenv import load_dotenv
from fastavro import parse_schema, reader, writer
from psycopg import sql

from app.db import connect

TIMESTAMP = {"type": "long", "logicalType": "timestamp-micros"}

# AVRO fields of each table: the same columns and types as the database.
FIELDS = {
    "departments": [("id", "int"), ("department", "string")],
    "jobs": [("id", "int"), ("job", "string")],
    "hired_employees": [
        ("id", "int"),
        ("name", "string"),
        ("datetime", TIMESTAMP),
        ("department_id", "int"),
        ("job_id", "int"),
    ],
}


def backup(table) -> None:
    columns = [name for name, _ in FIELDS[table]]
    schema = parse_schema({
        "type": "record",
        "name": table,
        "fields": [{"name": name, "type": kind} for name, kind in FIELDS[table]],
    })
    query = sql.SQL("SELECT {} FROM {} ORDER BY id").format(
        sql.SQL(", ").join(map(sql.Identifier, columns)), sql.Identifier(table)
    )
    folder = Path(os.environ.get("BACKUP_DIR", "backups"))
    folder.mkdir(exist_ok=True)
    path = folder / f"{table}_{datetime.now(timezone.utc):%Y%m%dT%H%M%SZ}.avro"

    with connect() as conn:
        rows = [dict(zip(columns, values)) for values in conn.execute(query)]
    with open(path, "wb") as handle:
        writer(handle, schema, rows)
    print(f"{table}: {len(rows)} rows saved to {path}")


def restore(table, path) -> None:
    columns = [name for name, _ in FIELDS[table]]
    with open(path, "rb") as handle:
        rows = [row for row in reader(handle) if isinstance(row, dict)]

    # 1. Insert the rows from the backup, or update them if they already exist.
    upsert = sql.SQL("INSERT INTO {} ({}) VALUES ({}) ON CONFLICT (id) DO UPDATE SET {}").format(
        sql.Identifier(table),
        sql.SQL(", ").join(map(sql.Identifier, columns)),
        sql.SQL(", ").join(sql.Placeholder() * len(columns)),
        sql.SQL(", ").join(sql.SQL("{0} = EXCLUDED.{0}").format(sql.Identifier(c)) for c in columns[1:]),
    )
    # 2. Delete the rows that are not in the backup.
    delete = sql.SQL("DELETE FROM {} WHERE NOT (id = ANY(%s))").format(sql.Identifier(table))

    # One transaction: if a delete breaks a foreign key, nothing is changed.
    try:
        with connect() as conn, conn.cursor() as cur:
            cur.executemany(upsert, [[row[c] for c in columns] for row in rows])
            cur.execute(delete, [[row["id"] for row in rows]])
            deleted = cur.rowcount
    except psycopg.errors.IntegrityError as error:
        raise SystemExit(f"Restore cancelled, nothing was changed: {error.diag.message_detail}")
    print(f"{table}: {len(rows)} rows restored from {path}, {deleted} rows removed")


def main() -> None:
    load_dotenv()
    match sys.argv[1:]:
        case ["backup", table] if table in FIELDS:
            backup(table)
        case ["restore", table, path] if table in FIELDS:
            restore(table, path)
        case _:
            raise SystemExit(__doc__)


if __name__ == "__main__":
    main()
