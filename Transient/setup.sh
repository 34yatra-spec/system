#!/usr/bin/env bash
# Transient setup — idempotent, never overwrites.
# Run from project root: bash Transient/setup.sh
# Or from inside: bash setup.sh
set -euo pipefail

# Find Transient dir and project root.
if [ -d "Transient" ]; then
  TRANSIENT_DIR="Transient"
  ROOT_DIR="."
elif [ -f "transient.md" ] && [ -f "AGENTS.snippet.md" ]; then
  TRANSIENT_DIR="."
  ROOT_DIR=".."
else
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  if [ -f "$SCRIPT_DIR/transient.md" ]; then
    TRANSIENT_DIR="$SCRIPT_DIR"
    ROOT_DIR="$(dirname "$SCRIPT_DIR")"
  else
    echo "ERROR: cannot find Transient/. Run as: bash Transient/setup.sh" >&2
    exit 1
  fi
fi

echo "Transient dir: $TRANSIENT_DIR"
echo "Project root: $ROOT_DIR"

mkdir -p "$TRANSIENT_DIR/full-sessions" "$TRANSIENT_DIR/refined-sessions" "$TRANSIENT_DIR/away-sessions" "$TRANSIENT_DIR/consult"

blank_if_missing() {
  local file="$1" title="$2" body="$3"
  if [ ! -f "$file" ]; then
    printf "# %s\n\nStatus: empty.\n\n%s\n" "$title" "$body" > "$file"
    echo "created: $file"
  else
    echo "kept: $file"
  fi
}

blank_if_missing "$TRANSIENT_DIR/rules.md" "Rules" "Master reference is Transient/transient.md. Update only on meaningful change."
blank_if_missing "$TRANSIENT_DIR/dictionary.md" "Dictionary" "Term: — definition: — path: — date:"
blank_if_missing "$TRANSIENT_DIR/desires.md" "Desires" "Wish: — priority: — date: — status: proposed/confirmed."
blank_if_missing "$TRANSIENT_DIR/goals.md" "Goals" "Goal: — tasks: — progress: — blocker: — date:"
blank_if_missing "$TRANSIENT_DIR/decisions.md" "Decisions" "Date: — decision: — reason: — status: confirmed/proposed/superseded — evidence:"
blank_if_missing "$TRANSIENT_DIR/project-timeline.md" "Project Timeline" "Stage: — tasks: — deps: — position: current/done/next."
blank_if_missing "$TRANSIENT_DIR/blockers.md" "Blockers" "Date: — issue: — cause: — recovery: — avoid-repeat:"
blank_if_missing "$TRANSIENT_DIR/checkpoints.md" "Checkpoints" "Format: checkpoint-N. Entry: date, stable state, changed files, return path, verify result."
blank_if_missing "$TRANSIENT_DIR/super-refined.md" "Super Refined" "Update from Transient/refined-sessions/ only. Mark replaced text as superseded."

for d in full-sessions refined-sessions away-sessions consult; do
  touch "$TRANSIENT_DIR/$d/.gitkeep" 2>/dev/null || true
done

# Wire root AGENTS.md without overwrite.
AGENTS_FILE="$ROOT_DIR/AGENTS.md"
MARK_START="<!-- TRANSIENT-INCLUDE-START -->"
MARK_END="<!-- TRANSIENT-INCLUDE-END -->"

if [ ! -f "$AGENTS_FILE" ]; then
  cat > "$AGENTS_FILE" <<'EOF'
# AGENTS

EOF
  printf "%s\nSee Transient/AGENTS.snippet.md. Full rules in Transient/transient.md.\n%s\n" "$MARK_START" "$MARK_END" >> "$AGENTS_FILE"
  echo "created root AGENTS.md with Transient include."
else
  if grep -q "TRANSIENT-INCLUDE-START" "$AGENTS_FILE"; then
    echo "root AGENTS.md already wired. No change."
  else
    cp "$AGENTS_FILE" "$AGENTS_FILE.bak-$(date +%Y%m%d-%H%M%S)"
    {
      echo ""
      echo "$MARK_START"
      echo "See Transient/AGENTS.snippet.md. Full rules in Transient/transient.md."
      echo "$MARK_END"
    } >> "$AGENTS_FILE"
    echo "appended Transient include to root AGENTS.md (backup made). No other lines touched."
  fi
fi

echo "Done. Next: read Transient/AGENTS.snippet.md and Transient/transient.md."
