#!/usr/bin/env bash
# Installs the stagehand-browser skill globally (Claude Code + ~/.agents for Codex/Gemini/Copilot).
# Idempotent: re-run after `git pull` any time.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SRC="$REPO_DIR/skills/stagehand-browser"
TARGETS=("$HOME/.claude/skills" "$HOME/.agents/skills")

say() { printf '\033[1m==>\033[0m %s\n' "$*"; }

# 1. Node >= 20.19 or >= 22.12 (required by the browse CLI)
command -v node >/dev/null || { echo "Node.js not found. Install Node 22+ (https://nodejs.org or nvm) and re-run." >&2; exit 1; }
node -e 'const [a,b]=process.versions.node.split(".").map(Number);process.exit((a===20&&b>=19)||(a===22&&b>=12)||a>=23?0:1)' \
  || { echo "Node $(node -v) is too old; need ^20.19 or >=22.12." >&2; exit 1; }
node -e 'const [a,b]=process.versions.node.split(".").map(Number);process.exit(a>22||(a===22&&b>=18)?0:1)' \
  || echo "WARNING: Node $(node -v) works but Stagehand 4.1+ declares >=22.18; upgrade when convenient." >&2

# 2. Chrome
if [[ -z "${CHROME_PATH:-}" && ! -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]] \
   && ! command -v google-chrome >/dev/null && ! command -v google-chrome-stable >/dev/null && ! command -v chromium >/dev/null; then
  echo "WARNING: Chrome not found. Install Google Chrome or set CHROME_PATH." >&2
fi

# 3. browse CLI (Stagehand v4)
if command -v browse >/dev/null && browse --version 2>/dev/null | grep -q '^browse/'; then
  say "browse already installed ($(browse --version | cut -d' ' -f1)); updating"
fi
npm install -g browse@latest --loglevel=error >/dev/null
say "browse $(browse --version | cut -d' ' -f1)"

# 4. Link the skill (symlink, so `git pull` updates every agent at once)
for t in "${TARGETS[@]}"; do
  mkdir -p "$t"
  dest="$t/stagehand-browser"
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    mv "$dest" "$dest.bak.$(date +%s)"; say "backed up existing $dest"
  fi
  ln -sfn "$SKILL_SRC" "$dest"
  say "linked $dest"
done

say "Done. Restart your agent session. First login:  bash ~/.claude/skills/stagehand-browser/scripts/chrome-profile.sh start"
