#!/bin/bash

# Script to check Product Constitution compliance
# Usage: ./docs/scripts/check-product-constitution.sh

set -e

DOCS_DIR="docs"
VIOLATIONS=0

echo "📋 Checking Product Constitution compliance..."
echo "=============================================="

# Define patterns that indicate violations
VIOLATION_PATTERNS=(
    "Добавим.*кнопк"
    "Предлагаю.*кнопк"
    "Используй.*кнопк"
    "Нажми.*кнопк"
    "Выбери.*кнопк"
    "/start"
    "/help"
    "/services"
    "/price"
    "inline.*клавиатур"
    "reply.*клавиатур"
)

# Check each pattern
for pattern in "${VIOLATION_PATTERNS[@]}"; do
    echo "🔍 Checking pattern: $pattern"

    # Find matches (excluding Product Constitution itself and prohibitions)
    matches=$(grep -r -i "$pattern" "$DOCS_DIR" \
        --exclude="constitution.md" \
        --exclude-dir=".git" \
        | grep -v -E "(ЗАПРЕЩЕНЫ|не используй|Никогда не предлагай|Product Constitution|❌|не поддерживаются)" \
        | grep -v -E "docs/scripts/" || true)

    if [[ -n "$matches" ]]; then
        echo "  ❌ VIOLATIONS FOUND:"
        echo "$matches" | while read -r match; do
            echo "    $match"
            VIOLATIONS=$((VIOLATIONS + 1))
        done
    else
        echo "  ✅ No violations found"
    fi
    echo ""
done

echo "=============================================="
echo "📊 Summary:"
echo "Total violations: $VIOLATIONS"

if [[ $VIOLATIONS -eq 0 ]]; then
    echo "🎉 Product Constitution is respected!"
    exit 0
else
    echo "💥 Found $VIOLATIONS Product Constitution violations!"
    echo ""
    echo "📖 Remember Product Constitution principles:"
    echo "  ❌ NO buttons, menus, or navigation"
    echo "  ❌ NO commands like /start, /help"
    echo "  ❌ NO inline keyboards"
    echo "  ✅ ONLY natural dialogue interaction"
    exit 1
fi