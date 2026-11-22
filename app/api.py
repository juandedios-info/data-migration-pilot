"""REST API to insert new rows into any of the three tables.

Usage: uv run uvicorn app.api:app --reload
"""

from typing import Annotated, Any, Literal

from dotenv import load_dotenv
from fastapi import Body, FastAPI

from app.db import connect, insert_rows

load_dotenv()

app = FastAPI(title="Data Migration PoC")


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
