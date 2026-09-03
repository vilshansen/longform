#!/usr/bin/env bash
# Publish Longform changes: optionally move a draft to the root, then commit + push.
# Usage:
#   scripts/publish.sh            # commit + push whatever changed
#   scripts/publish.sh my-post    # also move drafts/my-post.md into the library
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SLUG="${1:-}"
if [[ -n "$SLUG" ]]; then
    draft="$ROOT/drafts/${SLUG%.md}.md"
    if [[ ! -f "$draft" ]]; then
        echo "No draft found: $draft" >&2
        exit 1
    fi
    published="$ROOT/${SLUG%.md}.md"
    BLURB="$(sed -n 's/^blurb:[[:space:]]*//p' "$draft" | head -n 1)"
    if [[ -z "$BLURB" ]]; then
        echo "No blurb found in draft: $draft" >&2
        exit 1
    fi

    ROOT="$ROOT" DRAFT="$draft" PUBLISHED="$published" SLUG="${SLUG%.md}" BLURB="$BLURB" python3 <<'PY'
import json
import os
import re
from datetime import datetime
from pathlib import Path

root = Path(os.environ["ROOT"])
draft = Path(os.environ["DRAFT"])
published = Path(os.environ["PUBLISHED"])
slug = os.environ["SLUG"]
blurb = os.environ["BLURB"]
text = draft.read_text(encoding="utf-8")

match = re.match(r"\A---\r?\n.*?\r?\n---\r?\n(?:\r?\n)?", text, re.DOTALL)
if not match:
    raise SystemExit(f"Draft has no metadata block: {draft}")

body = text[match.end():]
heading = re.search(r"^#\s+(.+?)\s*$", body, re.MULTILINE)
title = heading.group(1).strip() if heading else slug.replace("-", " ").title()
manifest_path = root / "index.json"
posts = json.loads(manifest_path.read_text(encoding="utf-8"))
entry = {"file": f"{slug}.md", "title": title,
         "date": datetime.now().astimezone().isoformat(timespec="seconds"),
         "blurb": blurb}
posts = [post for post in posts if post.get("file") != entry["file"]]
posts.append(entry)
posts.sort(key=lambda post: post.get("date", ""), reverse=True)
manifest_path.write_text(json.dumps(posts, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
published.write_text(body, encoding="utf-8")
draft.unlink()
PY
    echo "Moved drafts/${SLUG%.md}.md -> ${SLUG%.md}.md"
fi

git add -A
if git diff --cached --quiet; then
    echo "Nothing to commit — nothing published."
    exit 0
fi

DATE="$(date +'%d %b %Y')"
MSG_FILE="$(mktemp)"
trap 'rm -f "$MSG_FILE"' EXIT
if [[ -n "$SLUG" ]]; then
    printf 'Publish %s (%s)\n' "${SLUG%.md}" "$DATE" > "$MSG_FILE"
else
    printf 'Update content (%s)\n' "$DATE" > "$MSG_FILE"
fi

git commit -F "$MSG_FILE"
git push origin main
echo "Published."
