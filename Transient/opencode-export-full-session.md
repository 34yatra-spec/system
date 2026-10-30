# Export FULL session transcript in OpenCode (not just context window)

Portable. No hard-coded box paths. Works on any studio.

For a fresh agent: the TUI scrollback and `/export` only show the context window.
The full transcript lives in the local SQLite store. This is how to dump it.

Tool: `Transient/tools/export-full.py`. It finds the project root, finds the DB,
writes to `Transient/full-sessions/`.

## 0. Version check (matters)

```bash
opencode --version
opencode session --help
```

- **v1.18.x:** `opencode session` has only `list` / `delete` — there is
  NO `session export` subcommand. Use the SQLite method below.
- **v2+:** `opencode session export <ses_id>` exists:
  ```bash
  opencode session list --max-count 20 --format json
  opencode session export ses_XXXX > full.json
  opencode session export ses_XXXX --sanitize > full-safe.json
  ```

## 1. Find the DB (never hard-code it)

```bash
opencode debug paths
# read the `data` line, DB is <data>/opencode.db
python3 Transient/tools/export-full.py --list
```

The script tries `opencode debug paths` first, then
`$XDG_DATA_HOME/opencode/opencode.db`, then
`~/.local/share/opencode/opencode.db`. Pass `--db <path>` to force it.

## 2. Store layout (v1.18.x)

- DB: `<data>/opencode.db` (open read-only: `file:...?mode=ro`)
- Tables: `session(id,title,directory,...)` → `message(id,session_id,data,time_created)`
  → `part(id,message_id,session_id,data,time_created)`
- `message.data` JSON has `role` (user/assistant). `part.data` JSON has `type`:
  `text` | `reasoning` | `tool` (with `state.status/input/output`) |
  `step-start` / `step-finish` / `compaction` / `patch` / `file`.

Check counts:

```bash
python3 -c "
import sqlite3, subprocess
from pathlib import Path
out = subprocess.run(['opencode','debug','paths'],capture_output=True,text=True).stdout
data = [l.split(None,1)[1] for l in out.splitlines() if l.strip().startswith('data')][0]
db = sqlite3.connect(f'file:{Path(data)/\"opencode.db\"}?mode=ro', uri=True)
print(db.execute('SELECT COUNT(*) FROM session').fetchone())
print(db.execute('SELECT COUNT(*) FROM message').fetchone())
print(db.execute('SELECT COUNT(*) FROM part').fetchone())
"
```

## 3. Dump to FULL markdown (portable)

```bash
# list sessions
python3 Transient/tools/export-full.py --list

# export last session (current work)
python3 Transient/tools/export-full.py

# export one session
python3 Transient/tools/export-full.py --session ses_XXXX

# export all
python3 Transient/tools/export-full.py --all

ls -lh Transient/full-sessions/FULL-*.md
```

Outputs go to `<project-root>/Transient/full-sessions/FULL-<session_id>.md`,
one per session. Rename to `YYYY-MM-DD-workN.md` per `Transient/transient.md`
Sec 12. Example: `Transient/full-sessions/2026-10-09-work1.md`.

History note (2026-10-02 box): 453 msgs / 1.1 MB + 18 msgs / 121 KB,
1730 parts total. Paths on that box are superseded. Do not reuse them.

## 4. Rules

- Open the DB `mode=ro` — never write to it.
- Order by `time_created`, never by rowid.
- Include full tool `output` — truncating it turns a FULL dump back into a context window.
- The DB has `-wal`/`-shm` files; query in place, do not move the DB.
- Large dumps (>1 MB) are normal.
