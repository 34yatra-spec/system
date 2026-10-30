#!/usr/bin/env python3
"""Export FULL OpenCode session transcripts to Transient/full-sessions/.
Portable: no hard-coded /kaggle, /root, or /teamspace paths.

Usage:
  python3 Transient/tools/export-full.py [--all] [--session ses_XXX] [--out Transient/full-sessions]
  python3 Transient/tools/export-full.py --list

Resolves:
  PROJECT_ROOT = nearest parent of CWD holding Transient/ (else CWD).
  DB = `opencode debug paths` -> data/opencode.db, with fallbacks:
    $XDG_DATA_HOME/opencode/opencode.db, ~/.local/share/opencode/opencode.db
"""
import argparse
import datetime
import json
import os
import sqlite3
import subprocess
import sys
from pathlib import Path


def find_project_root(start: Path) -> Path:
    for p in [start, *start.parents]:
        if (p / "Transient" / "transient.md").exists() or (p / "Transient").is_dir():
            return p
    return start


def find_db() -> Path:
    # 1. opencode debug paths (source of truth)
    try:
        out = subprocess.run(
            ["opencode", "debug", "paths"],
            capture_output=True, text=True, timeout=10,
        )
        if out.returncode == 0:
            for line in out.stdout.splitlines():
                s = line.strip()
                # format: "data       /path/to/share/opencode"
                if s.startswith("data"):
                    parts = s.split(None, 1)
                    if len(parts) == 2:
                        cand = Path(parts[1].strip()) / "opencode.db"
                        if cand.exists():
                            return cand
    except Exception:
        pass
    # 2. fallbacks
    cands = []
    xdg = os.environ.get("XDG_DATA_HOME")
    if xdg:
        cands.append(Path(xdg) / "opencode" / "opencode.db")
    cands += [
        Path.home() / ".local" / "share" / "opencode" / "opencode.db",
        Path("/root/.local/share/opencode/opencode.db"),
    ]
    for c in cands:
        if c.exists():
            return c
    raise FileNotFoundError(
        "opencode.db not found. Run `opencode debug paths` and pass --db <path>."
    )


def dump_session(db: sqlite3.Connection, sid: str, title: str, dir_: str) -> str:
    msgs = list(
        db.execute(
            "SELECT id,data,time_created FROM message WHERE session_id=? ORDER BY time_created",
            (sid,),
        )
    )
    out = [f"# {title}", f"session: {sid}  dir: {dir_}", f"messages: {len(msgs)}", ""]
    for mid, mdata, tc in msgs:
        try:
            m = json.loads(mdata)
        except Exception:
            m = {}
        role = m.get("role", "?")
        try:
            ts = datetime.datetime.fromtimestamp(tc / 1000, datetime.timezone.utc).strftime("%H:%M:%S")
        except Exception:
            ts = str(tc)
        out.append(f"## [{ts}] {role} ({mid})")
        try:
            parts = list(
                db.execute(
                    "SELECT data FROM part WHERE message_id=? ORDER BY time_created",
                    (mid,),
                )
            )
        except Exception:
            parts = []
        for (pdata,) in parts:
            try:
                p = json.loads(pdata)
            except Exception:
                continue
            t = p.get("type")
            if t == "text":
                out.append(p.get("text", ""))
            elif t == "reasoning":
                out.append("<details><summary>reasoning</summary>" + p.get("text", "") + "</details>")
            elif t == "tool":
                st = p.get("state", {}) or {}
                try:
                    inp = json.dumps(st.get("input", {}))[:400]
                except Exception:
                    inp = str(st.get("input", ""))[:400]
                out.append(f"TOOL {p.get('tool','?')} status={st.get('status')} input={inp}")
                if st.get("output"):
                    out.append("```\n" + str(st.get("output")) + "\n```")
            else:
                try:
                    out.append("_" + str(t) + ": " + json.dumps(p)[:300] + "_")
                except Exception:
                    out.append("_" + str(t) + "_")
        out.append("")
    return "\n".join(out)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--all", action="store_true", help="export every session (default: current/last)")
    ap.add_argument("--session", default="", help="single session id")
    ap.add_argument("--out", default="", help="output dir (default: <root>/Transient/full-sessions)")
    ap.add_argument("--db", default="", help="path to opencode.db")
    ap.add_argument("--list", action="store_true", help="list sessions and exit")
    args = ap.parse_args()

    cwd = Path.cwd()
    root = find_project_root(cwd)
    outdir = Path(args.out) if args.out else (root / "Transient" / "full-sessions")
    outdir.mkdir(parents=True, exist_ok=True)

    dbpath = Path(args.db) if args.db else find_db()
    print(f"db: {dbpath}")
    print(f"out: {outdir}")
    db = sqlite3.connect(f"file:{dbpath}?mode=ro", uri=True)

    sessions = list(db.execute("SELECT id,title,directory FROM session ORDER BY time_created"))
    if args.list:
        for sid, title, d in sessions[-20:]:
            print(f"{sid}  {title!r}  {d}")
        return 0
    if not sessions:
        print("no sessions found", file=sys.stderr)
        return 1

    targets = sessions
    if args.session:
        targets = [s for s in sessions if s[0] == args.session]
        if not targets:
            print(f"session not found: {args.session}", file=sys.stderr)
            return 1
    elif not args.all:
        targets = sessions[-1:]  # last session = current work

    for sid, title, d in targets:
        md = dump_session(db, sid, str(title), str(d))
        dest = outdir / f"FULL-{sid}.md"
        dest.write_text(md)
        print(f"wrote {dest} ({len(md)//1024} KB)")

    print("Next: copy/rename to Transient/full-sessions/YYYY-MM-DD-workN.md per Transient/transient.md Sec 12.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
