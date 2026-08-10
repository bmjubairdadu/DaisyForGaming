#!/bin/bash
# ============================================================================
# sync_to_github.sh - DaisyForGaming kernel source synchronization
#
# Run whenever kernel source / config / build files are modified:
#     ./scripts/sync_to_github.sh
#
# Behavior:
#   1. Detects changed kernel source files
#   2. Shows what changed
#   3. Scans staged content for secrets and aborts if any are found
#   4. Stages safe files (respects .gitignore)
#   5. Generates a meaningful commit message
#   6. Commits
#   7. Pushes to origin/main (never --force)
#   8. Stops safely on conflicts (no force-push, no overwrite)
#   9. Prints the resulting GitHub commit URL
# ============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; NC=$'\033[0m'

# --- sanity ---------------------------------------------------------------
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "${RED}Not inside a git repository.${NC}"; exit 1
fi
if ! git remote | grep -qx origin; then
    echo "${RED}No 'origin' remote configured. Add it first:${NC}"
    echo "  git remote add origin https://github.com/bmjubairdadu/DaisyForGaming.git"
    exit 1
fi

# --- 1. detect changes ----------------------------------------------------
if ! git status --porcelain | grep -q .; then
    echo "${GREEN}Working tree is clean - nothing to sync.${NC}"
    exit 0
fi

echo "${YELLOW}== Changed files ==${NC}"
git status --short
echo
git diff --stat
echo

# --- 3. secrets scan -------------------------------------------------------
echo "${YELLOW}== Scanning for secrets ==${NC}"
git add -A
SCAN_HITS=0
while IFS= read -r f; do
    [ -z "$f" ] && continue
    case "$f" in
        *.pem|*.key|*.p12|*.pfx|*.jks|*.keystore|id_rsa*|id_ed25519*)
            echo "${RED}SECRET CANDIDATE (extension): $f${NC}"; SCAN_HITS=$((SCAN_HITS+1));;
    esac
    if [ -f "$f" ]; then
        if grep -Eaq 'gh[ps]_[A-Za-z0-9]{15,}|AKIA[0-9A-Z]{16}|BEGIN (RSA |EC |OPENSSH |PGP )?PRIVATE KEY|BEGIN CERTIFICATE|api[_-]?key[[:space:]]*[:=][[:space:]]*["'"'"']?[A-Za-z0-9]{16,}|password[[:space:]]*[:=][[:space:]]*["'"'"']?[A-Za-z0-9]{8,}' "$f" 2>/dev/null; then
            echo "${RED}SECRET CANDIDATE (content): $f${NC}"; SCAN_HITS=$((SCAN_HITS+1))
        fi
    fi
done < <(git diff --cached --name-only)
if [ "$SCAN_HITS" -gt 0 ]; then
    echo "${RED}Aborting: possible secrets found. Remove them, then re-run.${NC}"
    git reset
    exit 1
fi
echo "${GREEN}No secrets detected.${NC}"

# --- 4/5/6. commit ---------------------------------------------------------
CHANGED=$(git diff --cached --name-only | tr '\n' ' ')
MSG="kernel: sync source $(date +%Y-%m-%d)

Files:
$(git diff --cached --name-only | sed 's/^/  - /')
"
git commit -m "$MSG"

# --- 7. push (never force) --------------------------------------------------
echo "${YELLOW}== Pushing to origin/main ==${NC}"
if ! git push origin HEAD:main; then
    echo "${RED}Push rejected (remote probably has commits you don't have).${NC}"
    echo "Fix it safely with:  git pull --rebase origin main"
    echo "Then re-run:          ./scripts/sync_to_github.sh"
    echo "Never use --force. ${YELLOW}If you really must rewrite history,"
    echo "prefer an explicit revert/commit instead.${NC}"
    exit 1
fi

# --- 9. commit URL ----------------------------------------------------------
SHA="$(git rev-parse HEAD)"
REMOTE_URL="$(git remote get-url origin)"
case "$REMOTE_URL" in
    *github.com*)
        case "$REMOTE_URL" in
            git@*|ssh://*) URL="${REMOTE_URL#*github.com:}";;
            https://github.com/*) URL="${REMOTE_URL#https://github.com/}";;
        esac
        URL="${URL%.git}"
        echo "${GREEN}Synced: https://github.com/$URL/commit/$SHA${NC}"
        ;;
    *)
        echo "${GREEN}Pushed commit: $SHA (remote: $REMOTE_URL)${NC}"
        ;;
esac
