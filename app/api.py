"""REST API: insert new rows into any table, and read the hiring metrics.

Usage: uv run uvicorn app.api:app --reload
"""

from pathlib import Path
from typing import Annotated, Any, Literal, LiteralString, cast

from dotenv import load_dotenv
from fastapi import Body, FastAPI
from psycopg.rows import dict_row

from app import ENV_FILE
from app.db import connect, insert_rows

load_dotenv(ENV_FILE)

app = FastAPI(title="Data Migration PoC")

METRICS = Path(__file__).parent.parent / "sql" / "metrics"


@app.post("/tables/{table}")
def insert_batch(
    table: Literal["departments", "jobs", "hired_employees"],
    rows: Annotated[list[dict[str, Any]], Body(min_length=1, max_length=1000)],
) -> dict:
    # Rows arrive as plain dictionaries, not as models: invalid rows must be
    # logged one by one, not reject the whole batch.
    with connect() as conn:
        inserted, rejected = insert_rows(conn, table, "api", rows)
        conn.commit()
    return {"table": table, "received": len(rows), "inserted": inserted, "rejected": rejected}


def run_metric(name) -> list[dict]:
    # The query comes from a SQL file in the repository, never from the request.
    query = cast(LiteralString, (METRICS / f"{name}.sql").read_text())
    with connect() as conn, conn.cursor(row_factory=dict_row) as cur:
        return cur.execute(query).fetchall()


@app.get("/metrics/hires-by-quarter")
def hires_by_quarter() -> list[dict]:
    return run_metric("hires_by_quarter")


@app.get("/metrics/departments-above-mean")
def departments_above_mean() -> list[dict]:
    return run_metric("departments_above_mean")
