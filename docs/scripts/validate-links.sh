#!/bin/bash

# Script to validate internal documentation links
# Usage: ./docs/scripts/validate-links.sh

set -e

DOCS_DIR="docs"
FAILED_LINKS=0
TOTAL_LINKS=0

echo "🔗 Validating internal links in documentation..."
echo "================================================"

# Find all markdown files in docs directory
find "$DOCS_DIR" -name "*.md" -type f | while read -r file; do
    echo "📄 Checking: $file"

    # Extract all relative markdown links
    grep -oE '\[([^]]*)\]\(([^)]+\.md)\)' "$file" | while read -r link; do
        TOTAL_LINKS=$((TOTAL_LINKS + 1))

        # Extract link path
        link_path=$(echo "$link" | sed -E 's/\[([^\]]*)\]\(([^)]+\.md)\)/\2/')

        # Get full path
        if [[ "$link_path" == /* ]]; then
            # Absolute path from repo root
            full_path="$link_path"
        else
            # Relative path from file directory
            file_dir=$(dirname "$file")
            full_path="$file_dir/$link_path"
        fi

        # Normalize path (remove ./ and ../)
        full_path=$(realpath -m "$full_path" 2>/dev/null || echo "$full_path")

        # Check if file exists
        if [[ ! -f "$full_path" ]]; then
            echo "  ❌ BROKEN LINK: $link_path -> $full_path"
            FAILED_LINKS=$((FAILED_LINKS + 1))
        else
            echo "  ✅ OK: $link_path"
        fi
    done
done

echo "================================================"
echo "📊 Summary:"
echo "Total links checked: $TOTAL_LINKS"
echo "Failed links: $FAILED_LINKS"

if [[ $FAILED_LINKS -eq 0 ]]; then
    echo "🎉 All links are valid!"
    exit 0
else
    echo "💥 Found $FAILED_LINKS broken links!"
    exit 1
fi