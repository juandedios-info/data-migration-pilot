"""Insert rows into the database and log the rejected ones."""

import psycopg
from psycopg import sql
from psycopg.types.json import Jsonb
from pydantic import ValidationError

from app.models import MODELS


def connect() -> psycopg.Connection:
    # Uses PGHOST, PGPORT, PGDATABASE and PGUSER. The password comes from ~/.pgpass.
    return psycopg.connect()


def reject(conn, table, source, raw, reason, error_code=None) -> None:
    conn.execute(
        "INSERT INTO rejected_rows (table_name, source, row_data, reason, error_code) "
        "VALUES (%s, %s, %s, %s, %s)",
        (table, source, Jsonb(raw), reason, error_code),
    )


def insert_rows(conn, table, source, raw_rows) -> tuple[int, int]:
    """Validate and insert rows. Returns (inserted, rejected)."""
    model = MODELS[table]
    columns = list(model.model_fields)
    insert = sql.SQL("INSERT INTO {} ({}) VALUES ({})").format(
        sql.Identifier(table),
        sql.SQL(", ").join(map(sql.Identifier, columns)),
        sql.SQL(", ").join(sql.Placeholder() * len(columns)),
    )
    inserted = rejected = 0

    for raw in raw_rows:
        # Data rules: required fields and types. Empty fields are left out,
        # so the reason says "Field required".
        try:
            row = model.model_validate({k: v for k, v in raw.items() if v is not None})
        except ValidationError as error:
            reason = "; ".join(f"{e['loc'][0]}: {e['msg']}" for e in error.errors())
            reject(conn, table, source, raw, reason)
            rejected += 1
            continue

        # Database rules: duplicate ids, foreign keys (IntegrityError), and
        # values the column types do not accept, for example an id larger
        # than INTEGER (DataError). The savepoint undoes only this row.
        try:
            with conn.transaction():
                conn.execute(insert, [getattr(row, c) for c in columns])
            inserted += 1
        except (psycopg.errors.IntegrityError, psycopg.errors.DataError) as error:
            reject(conn, table, source, raw, error.diag.message_primary, error.sqlstate)
            rejected += 1

    return inserted, rejected
