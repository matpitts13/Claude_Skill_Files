"""
Run a read-only SQL query against ~/.claude/chronicle.db.

Usage:
  python chronicle_query.py "SELECT session_id, cwd, started_at, num_turns FROM sessions ORDER BY started_at DESC LIMIT 10"

Run chronicle_index.py first (or after new sessions) to keep the DB current.
"""
import sqlite3
import sys
from pathlib import Path

DB_PATH = Path.home() / ".claude" / "chronicle.db"


def main():
    if len(sys.argv) != 2:
        print('Usage: python chronicle_query.py "<SQL>"')
        raise SystemExit(1)
    if not DB_PATH.exists():
        print(f"No chronicle DB at {DB_PATH} - run chronicle_index.py first.")
        raise SystemExit(1)

    con = sqlite3.connect(f"file:{DB_PATH}?mode=ro", uri=True)
    cur = con.cursor()
    cur.execute(sys.argv[1])
    cols = [d[0] for d in cur.description] if cur.description else []
    if cols:
        print(" | ".join(cols))
    for row in cur.fetchall():
        print(" | ".join(str(v) for v in row))


if __name__ == "__main__":
    main()
