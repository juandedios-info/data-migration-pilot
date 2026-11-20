# Data Migration PoC

Proof of concept for migrating historical CSV data into a SQL database,
with a REST API to ingest new records and AVRO-based table backup and restore.

## Status

Work in progress.

## Planned features

- Load historical CSV files into PostgreSQL
- REST API to insert batches of 1 to 1,000 rows per request, with validation
- Logging of rows that fail validation
- Table backup to AVRO and restore from a backup
- Analytics endpoints for hiring metrics

## Tech stack

- Python 3.12, managed with uv
- PostgreSQL
- FastAPI

## Getting started

Coming soon.
