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
    mv "$draft" "$ROOT/${SLUG%.md}.md"
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
