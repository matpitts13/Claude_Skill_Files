"""
Incrementally indexes Claude Code session transcripts (~/.claude/projects/*/*.jsonl)
into a queryable SQLite DB at ~/.claude/chronicle.db.

Machine-wide, cross-project raw session history - the "what did we do in
project X" ground truth beneath the curated CLAUDE.md / auto-memory files.

Safe to re-run: tracks a per-file byte offset in _index_state so repeat runs
only parse newly-appended lines.
"""
import json
import sqlite3
from pathlib import Path

PROJECTS_DIR = Path.home() / ".claude" / "projects"
DB_PATH = Path.home() / ".claude" / "chronicle.db"

TURN_TYPES = {"user", "assistant"}
FILE_TOOLS = {"Edit", "Write", "Read", "NotebookEdit", "MultiEdit"}

SCHEMA = """
CREATE TABLE IF NOT EXISTS sessions (
    session_id TEXT PRIMARY KEY,
    project_dir TEXT,
    cwd TEXT,
    git_branch TEXT,
    started_at TEXT,
    ended_at TEXT,
    num_turns INTEGER DEFAULT 0,
    total_input_tokens INTEGER DEFAULT 0,
    total_output_tokens INTEGER DEFAULT 0
);
CREATE TABLE IF NOT EXISTS turns (
    session_id TEXT,
    line_no INTEGER,
    role TEXT,
    timestamp TEXT,
    is_sidechain INTEGER,
    text_preview TEXT,
    input_tokens INTEGER,
    output_tokens INTEGER,
    PRIMARY KEY (session_id, line_no)
);
CREATE TABLE IF NOT EXISTS session_files (
    session_id TEXT,
    line_no INTEGER,
    tool TEXT,
    file_path TEXT,
    timestamp TEXT
);
CREATE TABLE IF NOT EXISTS _index_state (
    file_path TEXT PRIMARY KEY,
    last_line INTEGER DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_turns_session ON turns(session_id);
CREATE INDEX IF NOT EXISTS idx_files_session ON session_files(session_id);
CREATE INDEX IF NOT EXISTS idx_sessions_cwd ON sessions(cwd);
"""


def text_preview(content, limit=300):
    if isinstance(content, str):
        text = content
    elif isinstance(content, list):
        text = ""
        for block in content:
            if isinstance(block, dict) and block.get("type") == "text":
                text = block.get("text", "")
                break
    else:
        text = ""
    text = " ".join(text.split())
    return text[:limit]


def extract_file_ops(content, session_id, line_no, timestamp, rows):
    if not isinstance(content, list):
        return
    for block in content:
        if isinstance(block, dict) and block.get("type") == "tool_use":
            name = block.get("name")
            if name in FILE_TOOLS:
                fp = (block.get("input") or {}).get("file_path")
                if fp:
                    rows.append((session_id, line_no, name, fp, timestamp))


def index_file(con, jsonl_path: Path):
    cur = con.cursor()
    cur.execute("SELECT last_line FROM _index_state WHERE file_path = ?", (str(jsonl_path),))
    row = cur.fetchone()
    start_line = row[0] if row else 0

    touched_sessions = set()
    file_rows = []
    line_no = 0
    with jsonl_path.open(encoding="utf-8") as f:
        for line_no, line in enumerate(f, start=1):
            if line_no <= start_line:
                continue
            line = line.strip()
            if not line:
                continue
            try:
                d = json.loads(line)
            except json.JSONDecodeError:
                continue
            if d.get("type") not in TURN_TYPES:
                continue

            session_id = d.get("sessionId")
            if not session_id:
                continue
            cwd = d.get("cwd")
            git_branch = d.get("gitBranch")
            timestamp = d.get("timestamp")
            is_sidechain = 1 if d.get("isSidechain") else 0
            message = d.get("message") or {}
            role = message.get("role", d.get("type"))
            content = message.get("content")
            usage = message.get("usage") or {}

            cur.execute(
                """INSERT OR REPLACE INTO turns
                   (session_id, line_no, role, timestamp, is_sidechain, text_preview, input_tokens, output_tokens)
                   VALUES (?,?,?,?,?,?,?,?)""",
                (session_id, line_no, role, timestamp, is_sidechain,
                 text_preview(content), usage.get("input_tokens", 0), usage.get("output_tokens", 0)),
            )

            cur.execute(
                """INSERT OR REPLACE INTO sessions (session_id, project_dir, cwd, git_branch, started_at)
                   VALUES (?,?,?,?,COALESCE((SELECT started_at FROM sessions WHERE session_id=?), ?))""",
                (session_id, jsonl_path.parent.name, cwd, git_branch, session_id, timestamp),
            )
            touched_sessions.add(session_id)
            extract_file_ops(content, session_id, line_no, timestamp, file_rows)

    if file_rows:
        cur.executemany(
            "INSERT INTO session_files (session_id, line_no, tool, file_path, timestamp) VALUES (?,?,?,?,?)",
            file_rows,
        )

    for session_id in touched_sessions:
        cur.execute(
            """UPDATE sessions SET
                 started_at = (SELECT MIN(timestamp) FROM turns WHERE session_id=?),
                 ended_at   = (SELECT MAX(timestamp) FROM turns WHERE session_id=?),
                 num_turns  = (SELECT COUNT(*) FROM turns WHERE session_id=?),
                 total_input_tokens  = (SELECT COALESCE(SUM(input_tokens),0) FROM turns WHERE session_id=?),
                 total_output_tokens = (SELECT COALESCE(SUM(output_tokens),0) FROM turns WHERE session_id=?)
               WHERE session_id=?""",
            (session_id, session_id, session_id, session_id, session_id, session_id),
        )

    cur.execute(
        "INSERT INTO _index_state (file_path, last_line) VALUES (?,?) "
        "ON CONFLICT(file_path) DO UPDATE SET last_line=excluded.last_line",
        (str(jsonl_path), line_no),
    )
    con.commit()
    return line_no - start_line


def main():
    con = sqlite3.connect(DB_PATH)
    con.executescript(SCHEMA)

    total_new = 0
    files_touched = 0
    for jsonl_path in PROJECTS_DIR.glob("*/*.jsonl"):
        new_lines = index_file(con, jsonl_path)
        if new_lines:
            files_touched += 1
            total_new += new_lines

    con.close()
    print(f"Chronicle updated: {total_new} new line(s) across {files_touched} file(s) -> {DB_PATH}")


if __name__ == "__main__":
    main()
