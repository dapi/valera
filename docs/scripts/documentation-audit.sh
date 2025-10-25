#!/bin/bash

# Documentation Audit Script
# Runs comprehensive documentation quality checks
# Usage: ./docs/scripts/documentation-audit.sh

set -e

echo "📚 COMPREHENSIVE DOCUMENTATION AUDIT"
echo "===================================="
echo "Started at: $(date)"
echo ""

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$(dirname "$SCRIPT_DIR")"

# Track overall status
OVERALL_STATUS=0

echo "🔗 Step 1: Validating internal links..."
if "$SCRIPT_DIR/validate-links.sh"; then
    echo "✅ Links validation PASSED"
else
    echo "❌ Links validation FAILED"
    OVERALL_STATUS=1
fi
echo ""

echo "📋 Step 2: Checking Product Constitution compliance..."
if "$SCRIPT_DIR/check-product-constitution.sh"; then
    echo "✅ Product Constitution compliance PASSED"
else
    echo "❌ Product Constitution compliance FAILED"
    OVERALL_STATUS=1
fi
echo ""

echo "📁 Step 3: Checking documentation structure..."
EXPECTED_DIRS=("requirements" "product" "gems" "tdd" "prompts" "domain")
EXPECTED_FILES=("FLOW.md" "README.md")

for dir in "${EXPECTED_DIRS[@]}"; do
    if [[ -d "$DOCS_DIR/$dir" ]]; then
        echo "✅ Directory exists: $dir"
    else
        echo "❌ Directory missing: $dir"
        OVERALL_STATUS=1
    fi
done

for file in "${EXPECTED_FILES[@]}"; do
    if [[ -f "$DOCS_DIR/$file" ]]; then
        echo "✅ File exists: $file"
    else
        echo "❌ File missing: $file"
        OVERALL_STATUS=1
    fi
done
echo ""

echo "🔄 Step 4: Checking FLOW structure compliance..."
USER_STORIES_COUNT=$(find "$DOCS_DIR/requirements/user-stories" -name "US-*.md" -type f | wc -l)
TDD_DOCS_COUNT=$(find "$DOCS_DIR/tdd" -name "TDD-*.md" -type f | wc -l)

echo "User Stories found: $USER_STORIES_COUNT"
echo "TDD Documents found: $TDD_DOCS_COUNT"

if [[ $USER_STORIES_COUNT -eq $TDD_DOCS_COUNT ]]; then
    echo "✅ FLOW structure compliance PASSED (equal US and TDD counts)"
else
    echo "❌ FLOW structure compliance FAILED (US: $USER_STORIES_COUNT, TDD: $TDD_DOCS_COUNT)"
    OVERALL_STATUS=1
fi
echo ""

echo "📊 Step 5: Documentation metrics..."
TOTAL_MD_FILES=$(find "$DOCS_DIR" -name "*.md" -type f | wc -l)
TOTAL_SIZE=$(du -sh "$DOCS_DIR" | cut -f1)

echo "Total markdown files: $TOTAL_MD_FILES"
echo "Total documentation size: $TOTAL_SIZE"
echo ""

echo "===================================="
echo "📊 AUDIT SUMMARY"
echo "===================================="
echo "Completed at: $(date)"

if [[ $OVERALL_STATUS -eq 0 ]]; then
    echo "🎉 ALL CHECKS PASSED!"
    echo "✅ Documentation is healthy and compliant"
else
    echo "💥 SOME CHECKS FAILED!"
    echo "❌ Please review and fix the issues above"
fi

exit $OVERALL_STATUS