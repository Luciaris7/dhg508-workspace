"""Build data.db from records.json. Standard library only.

Usage:
    python build_db.py

Reads records.json in the same folder, writes (or overwrites) data.db
with one row per fact in the `events` table.
"""

import json
import os
import sqlite3

HERE = os.path.dirname(os.path.abspath(__file__))
RECORDS = os.path.join(HERE, "records.json")
DB = os.path.join(HERE, "data.db")

SCHEMA = """
CREATE TABLE events (
    id     INTEGER PRIMARY KEY,
    year   INTEGER,
    date   TEXT,
    event  TEXT NOT NULL,
    place  TEXT,
    people TEXT,
    source TEXT NOT NULL,
    note   TEXT
);
"""


def main():
    with open(RECORDS, encoding="utf-8") as fh:
        records = json.load(fh)

    if os.path.exists(DB):
        os.remove(DB)

    con = sqlite3.connect(DB)
    con.execute(SCHEMA)
    con.executemany(
        """INSERT INTO events (id, year, date, event, place, people, source, note)
           VALUES (:id, :year, :date, :event, :place, :people, :source, :note)""",
        records,
    )
    con.commit()

    rows = con.execute("SELECT COUNT(*) FROM events").fetchone()[0]
    span = con.execute("SELECT MIN(year), MAX(year) FROM events").fetchone()
    print(f"wrote {rows} rows to {DB}")
    print(f"year span: {span[0]}–{span[1]}")

    print("\nsample:")
    for row in con.execute(
        "SELECT id, year, date, event FROM events ORDER BY year, id LIMIT 3"
    ):
        print(" ", row)

    con.close()


if __name__ == "__main__":
    main()
