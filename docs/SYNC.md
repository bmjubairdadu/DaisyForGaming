# Source synchronization

Run this **whenever you modify kernel source, configs, or build files**:

```bash
./scripts/sync_to_github.sh
```

## What it does

1. Detects changed/untracked files (`git status --porcelain`)
2. Shows you exactly what changed
3. Stages everything that is not git-ignored
4. **Scans for secrets** (GitHub PAT tokens, AWS access keys, private key
   blocks, `api_key=`/`password=` assignments, and `.pem`/`.key`/`.p12`/
   `.jks` filenames) — **aborts** if anything is found
5. Commits with an auto-generated message listing the changed files
6. Pushes to `origin/main` — **never** `--force`
7. Prints the GitHub commit URL

## If the push is rejected

The remote has commits you don't have. Fix it safely:

```bash
git pull --rebase origin main
./scripts/sync_to_github.sh
```

Never force-push. If you must undo a bad commit, prefer a new revert commit.

## Keeping secrets out

- Kernel build outputs (`out/`, `.config`, `dist/`, `*.zip`) are git-ignored.
- The scan aborts the push if it detects a secret — remove the file first.
- Release tags are created by `release_kernel.sh`, not by syncing.
