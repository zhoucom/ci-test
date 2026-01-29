#!/bin/bash
# ==============================================================================
# Script: check_quality_lite.sh
# Purpose: Check PMD report for critical issues without a heavy server.
# Usage: ./check_quality_lite.sh <PMD_XML_PATH> <MAX_ISSUES>
# ==============================================================================

REPORT_FILE="$1"
MAX_ISSUES="$2"

if [ ! -f "$REPORT_FILE" ]; then
    echo "Warning: PMD Report not found at $REPORT_FILE. Skipping check."
    exit 0
fi

# Count the number of <violation> tags in the XML
ISSUE_COUNT=$(grep -c "<violation" "$REPORT_FILE")

echo "--------------------------------------------------------"
echo "Quality Check Results:"
echo "Report Path: $REPORT_FILE"
echo "Issues Found: $ISSUE_COUNT"
echo "Max Allowed:  $MAX_ISSUES"
echo "--------------------------------------------------------"

if [ "$ISSUE_COUNT" -gt "$MAX_ISSUES" ]; then
    echo "FAILED: Quality issues count ($ISSUE_COUNT) exceeds the limit of $MAX_ISSUES!"
    exit 1
else
    echo "PASSED: Quality check successful."
    exit 0
fi
