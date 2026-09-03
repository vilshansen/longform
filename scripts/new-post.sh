#!/usr/bin/env bash
# Scaffold a new Longform post in drafts/ and open it in nano for writing.
# Usage: scripts/new-post.sh "My Awesome Post"
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRAFTS="$ROOT/drafts"
mkdir -p "$DRAFTS"

TITLE="${1:-}"
if [[ -z "$TITLE" ]]; then
    read -r -p "Post title: " TITLE
fi
if [[ -z "$TITLE" ]]; then
    echo "No title given; aborting." >&2
    exit 1
fi

slug="$(printf '%s' "$TITLE" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')"
[[ -n "$slug" ]] || slug="draft"

file="$DRAFTS/$slug.md"
if [[ -e "$file" ]]; then
    echo "Already exists: $file" >&2
    exit 1
fi

{
    printf '# %s\n' "$TITLE"
    printf '\n'
    printf 'Start writing…\n'
} > "$file"

echo "Created $file — opening nano. Write, then Ctrl+X, Y, Enter to save."
nano "$file"
echo "Saved. Add this post to index.json, then publish with: ./scripts/publish.sh $slug"
