#!/bin/bash
#
# Update CHANGELOG.md using Codex CLI (default) or Claude CLI
#
# Usage:
#   ./scripts/update_changelog.sh           # Update changelog for current .semver version
#   ./scripts/update_changelog.sh 3.55.0    # Update changelog for specific version
#   ./scripts/update_changelog.sh --dry-run # Preview without modifying file
#   CHANGELOG_AGENT=claude ./scripts/update_changelog.sh       # Use Claude instead of Codex
#   CHANGELOG_AGENT=kimi-claude ./scripts/update_changelog.sh  # Use Kimi Claude CLI
#

set -e

SEMVER_BIN="./bin/semver"
CHANGELOG_FILE="CHANGELOG.md"
DRY_RUN=false
CHANGELOG_AGENT="${CHANGELOG_AGENT:-codex}"

case "$CHANGELOG_AGENT" in
    codex|claude|kimi-claude)
        ;;
    *)
        echo "Error: CHANGELOG_AGENT must be 'codex', 'claude', or 'kimi-claude' (got '$CHANGELOG_AGENT')"
        exit 1
        ;;
esac

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run|-n)
            DRY_RUN=true
            shift
            ;;
        *)
            VERSION="$1"
            shift
            ;;
    esac
done

# Get version from .semver if not provided
if [ -z "$VERSION" ]; then
    VERSION=$($SEMVER_BIN)
fi

# Remove 'v' prefix if present
VERSION="${VERSION#v}"

# Get the latest tag
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

if [ -z "$LATEST_TAG" ]; then
    echo "No tags found, using first commit as base"
    PREV_TAG=$(git rev-list --max-parents=0 HEAD)
else
    PREV_TAG="$LATEST_TAG"
fi

echo "Generating changelog for version $VERSION"
echo "Changes since: $PREV_TAG"
echo ""

# Get commits since last tag (excluding merge commits, version bumps, and minor/patch commits)
COMMITS=$(git log "$PREV_TAG"..HEAD --pretty=format:'- %s' --no-merges 2>/dev/null | \
    grep -v "^- v[0-9]" | \
    grep -v "^- Merge" | \
    grep -v "^- minor$" | \
    grep -v "^- patch$" | \
    grep -v "^- Release " || true)

if [ -z "$COMMITS" ]; then
    echo "No commits found since $PREV_TAG"
    echo ""
    echo "This might mean:"
    echo "  - You're on the same commit as the latest tag"
    echo "  - All commits are merge/version commits"
    echo ""
    echo "If you just bumped the version, run the release first, then update changelog."
    exit 0
fi

echo "Commits to process:"
echo "$COMMITS"
echo ""

# Generate changelog section using AI CLI
TODAY=$(date +%Y-%m-%d)

PROMPT="Generate a CHANGELOG.md section for version $VERSION.

Input commits (conventional commits format):
$COMMITS

Rules:
1. Group by Keep a Changelog categories:
   - Added (for feat: commits)
   - Changed (for chore:, refactor: commits)
   - Fixed (for fix: commits)
   - Deprecated
   - Removed
   - Security
2. Remove prefixes (feat:, fix:, chore:, refactor:) from text
3. Skip docs:, ci:, style:, test: commits - they don't go into changelog
4. If a commit contains details after a dash, keep them as sub-items
5. Merge duplicate commits (e.g., multiple 'update submodule')
6. Output format - only markdown section, no explanations or comments

Format:
## [$VERSION] - $TODAY

### Added
- Description of new feature

### Fixed
- Description of fix

Output ONLY the markdown changelog section, nothing else. Do not add triple backticks or other formatting."

echo "Calling ${CHANGELOG_AGENT} CLI..."

# Call selected CLI
if [ "$CHANGELOG_AGENT" = "claude" ]; then
    CHANGELOG_SECTION=$(echo "$PROMPT" | claude -p --output-format text 2>/dev/null)

    if [ -z "$CHANGELOG_SECTION" ]; then
        echo "Error: Failed to generate changelog with Claude"
        echo "Make sure claude CLI is installed and authenticated"
        exit 1
    fi
elif [ "$CHANGELOG_AGENT" = "kimi-claude" ]; then
    CHANGELOG_SECTION=$(echo "$PROMPT" | kimi-claude -p --output-format text 2>/dev/null)

    if [ -z "$CHANGELOG_SECTION" ]; then
        echo "Error: Failed to generate changelog with Kimi Claude"
        echo "Make sure kimi-claude CLI is installed and authenticated"
        exit 1
    fi
else
    CODEX_OUTPUT_FILE=$(mktemp)
    if ! echo "$PROMPT" | codex exec --output-last-message "$CODEX_OUTPUT_FILE" - >/dev/null 2>&1; then
        rm -f "$CODEX_OUTPUT_FILE"
        echo "Error: Failed to generate changelog with Codex"
        echo "Make sure codex CLI is installed and authenticated"
        exit 1
    fi

    CHANGELOG_SECTION=$(cat "$CODEX_OUTPUT_FILE")
    rm -f "$CODEX_OUTPUT_FILE"

    if [ -z "$CHANGELOG_SECTION" ]; then
        echo "Error: Codex returned empty changelog section"
        exit 1
    fi
fi

echo ""
echo "Generated changelog section:"
echo "========================================"
echo "$CHANGELOG_SECTION"
echo "========================================"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo "[DRY RUN] No changes made to $CHANGELOG_FILE"
    exit 0
fi

# Create temporary file with new content
TEMP_FILE=$(mktemp)

# Insert new section after [Unreleased]
awk -v section="$CHANGELOG_SECTION" '
    /^## \[Unreleased\]/ {
        print
        print ""
        print section
        next
    }
    { print }
' "$CHANGELOG_FILE" > "$TEMP_FILE"

# Replace original file
mv "$TEMP_FILE" "$CHANGELOG_FILE"

echo "CHANGELOG.md updated successfully!"
echo ""
echo "Next steps:"
echo "  1. Review: git diff $CHANGELOG_FILE"
echo "  2. Commit: git add $CHANGELOG_FILE && git commit -m 'docs: update changelog for $VERSION'"
