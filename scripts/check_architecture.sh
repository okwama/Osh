#!/bin/bash

# Pre-commit hook to check architecture rules
# This script ensures:
# 1. No files in lib/ exceed 650 lines
# 2. No empty catch blocks exist
# 3. No UI files import database services directly
# 4. All new files follow architecture rules

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Helper function to fail the commit
fail() {
    print_error "ERROR: $1"
    exit 1
}

# 1. Check for files in lib/ exceeding 650 lines
echo "Checking for files in lib/ exceeding 650 lines..."
for file in $(find lib/ -name "*.dart" -type f); do
    lines=$(wc -l < "$file")
    if [ "$lines" -gt 650 ]; then
        fail "$file exceeds 650 lines ($lines lines)"
    fi
done
print_status "All files are under 650 lines"

# 2. Check for empty catch blocks
echo "Checking for empty catch blocks..."
empty_catches=$(grep -r "catch.*{" lib/ --include="*.dart" | grep -B1 -A1 "}" | grep -E "catch.*\{\s*\}" || true)
if [ -n "$empty_catches" ]; then
    print_warning "Found empty catch blocks:"
    echo "$empty_catches"
    fail "Empty catch blocks are not allowed. Add proper error handling."
fi
print_status "No empty catch blocks found"

# 3. Check for UI files importing database services directly
echo "Checking for UI files importing database services..."
ui_files=$(find lib/pages/ lib/widgets/ -name "*.dart" -type f 2>/dev/null || true)
for file in $ui_files; do
    if grep -q "import.*database.*service" "$file" 2>/dev/null; then
        fail "$file imports database services directly. Use controllers instead."
    fi
    if grep -q "import.*core.*service" "$file" 2>/dev/null; then
        fail "$file imports core services directly. Use controllers instead."
    fi
done
print_status "No UI files import database services directly"

# 4. Check architecture rules for new files
echo "Checking architecture rules for new files..."
staged_files=$(git diff --cached --name-only --diff-filter=A | grep "\.dart$" || true)
for file in $staged_files; do
    if [[ "$file" == lib/pages/* ]] || [[ "$file" == lib/widgets/* ]]; then
        # Check if UI files have business logic
        if grep -q "await.*Service\." "$file" 2>/dev/null; then
            fail "$file contains direct service calls. Move business logic to controllers."
        fi
    fi
done
print_status "All new files follow architecture rules"

echo -e "${GREEN}All checks passed!${NC}"