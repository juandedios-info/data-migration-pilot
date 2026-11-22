"""Data rules for each table, shared by the CSV loader and the API."""

from pydantic import AwareDatetime, BaseModel, ConfigDict, Field


class Row(BaseModel):
    # Remove spaces at the start and the end of text values.
    model_config = ConfigDict(str_strip_whitespace=True)


class Department(Row):
    id: int
    department: str = Field(min_length=1)


class Job(Row):
    id: int
    job: str = Field(min_length=1)


class HiredEmployee(Row):
    id: int
    name: str = Field(min_length=1)
    datetime: AwareDatetime  # ISO 8601 with a time zone, for example 2021-07-27T16:02:08Z
    department_id: int
    job_id: int


# Table name -> model, in load order: reference tables first, because of the foreign keys.
MODELS: dict[str, type[Row]] = {
    "departments": Department,
    "jobs": Job,
    "hired_employees": HiredEmployee,
}
