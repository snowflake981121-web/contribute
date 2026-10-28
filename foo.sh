#!/usr/bin/env bash
set -Eeuo pipefail

# Repository, base branch, and co-author for this contribution.
REPO="snowflake981121-web/contribute"
BASE="slarkmaster-branch"
COAUTHOR_NAME="slarkmaster"
COAUTHOR_EMAIL="dennisjacobs.sn@gmail.com"

# Verify required tools.
for cmd in git gh; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: $cmd is not installed."
        exit 1
    fi
done

gh auth status

# Ensure we are inside a Git repository.
git rev-parse --is-inside-work-tree >/dev/null

# Don't overwrite or include existing uncommitted changes.
if [[ -n "$(git status --porcelain)" ]]; then
    echo "Error: Your working tree is not clean."
    echo "Commit or stash your existing changes before continuing."
    exit 1
fi

echo "Repository: $REPO"
echo "Base branch: $BASE"
echo "Co-author: $COAUTHOR_NAME <$COAUTHOR_EMAIL>"

# Update the base branch.
git fetch origin
git switch "$BASE"
git pull --ff-only origin "$BASE"

# Create a unique branch and documentation file.
SUFFIX="$(date +%Y%m%d%H%M%S)"
BRANCH="docs/pair-extraordinaire-$SUFFIX"
FILE="docs/collaboration-guide-$SUFFIX.md"

git switch -c "$BRANCH"

mkdir -p docs

cat > "$FILE" <<'EOF'
# Collaboration Guide

## Making a contribution

1. Choose a focused task.
2. Create a feature branch.
3. Make and test your changes.
4. Write a clear commit message.
5. Open a pull request describing the change.

## Reviewing a contribution

1. Check that the change addresses its intended purpose.
2. Review the documentation and tests.
3. Provide constructive feedback.
4. Confirm that required checks pass before merging.
EOF

git add "$FILE"

# Create a commit that credits the genuine co-author.
git commit \
    -m "docs: add collaboration guide" \
    -m "Co-authored-by: $COAUTHOR_NAME <$COAUTHOR_EMAIL>"

echo
echo "Checking the co-author trailer:"
git log -1 --format=%B
echo

# Push the branch.
git push -u origin "$BRANCH"

# Create the pull request.
PR_URL=$(gh pr create \
    --repo "$REPO" \
    --base "$BASE" \
    --head "$BRANCH" \
    --title "docs: add collaboration guide" \
    --body "Adds a collaboration guide. The commit credits a genuine co-author.")

echo
echo "Pull Request created: $PR_URL"

# Ask for confirmation before merging.
read -r -p "Merge this Pull Request now? (yes/no): " ANSWER

if [[ "$ANSWER" != "yes" ]]; then
    echo "PR remains open: $PR_URL"
    echo "Review it on GitHub and merge it when appropriate."
    exit 0
fi

# Use a merge commit to preserve the original co-authored commit
# in the target branch's history.
gh pr merge "$PR_URL" --repo "$REPO" --merge --delete-branch

echo
echo "Merge command completed."
echo "Check the merged PR and commit history on GitHub."
echo "Achievement eligibility is determined by GitHub."
