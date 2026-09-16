#!/usr/bin/env bash
set -euo pipefail

AGENT=".claude/agents/security-engineer.md"
INBOX=".state/inbox/security-engineer.md"

if [ ! -f "$INBOX" ] || [ ! -s "$INBOX" ]; then
  echo "ERROR: No inbox file at $INBOX (or it's empty)."
  echo "The engineering-manager must write one first."
  exit 1
fi

echo "Invoking security-engineer agent..."
echo "Inbox: $INBOX"
echo "---"

claude --agent "$AGENT" < "$INBOX"
