#!/bin/bash
# ==============================================================================
# Script: check_coverage.sh
# Purpose: Parse JaCoCo XML and enforce coverage thresholds.
# Usage: ./check_coverage.sh <JACOCO_XML_PATH> <MIN_COVERAGE> [MODE]
#   MODE: total (default) | incremental (placeholder for now)
# ==============================================================================

XML_FILE="$1"
THRESHOLD="$2"
MODE="${3:-total}"

if [ ! -f "$XML_FILE" ]; then
    echo "Error: JaCoCo XML not found at $XML_FILE"
    exit 1
fi

echo "Checking coverage for $XML_FILE (Threshold: $THRESHOLD%)..."

# Extract covered and missed instructions
# Format: <counter type="INSTRUCTION" missed="435" covered="123"/>
MISSED=$(grep -oP '(?<=<counter type="INSTRUCTION" missed=")\d+' "$XML_FILE" | head -1)
COVERED=$(grep -oP '(?<=covered=")\d+' "$XML_FILE" | head -1)

if [ -z "$MISSED" ] || [ -z "$COVERED" ]; then
    # Fallback for systems without -P (perl-regex)
    MISSED=$(grep 'type="INSTRUCTION"' "$XML_FILE" | head -1 | sed -n 's/.*missed="\([^"]*\)".*/\1/p')
    COVERED=$(grep 'type="INSTRUCTION"' "$XML_FILE" | head -1 | sed -n 's/.*covered="\([^"]*\)".*/\1/p')
fi

TOTAL=$((MISSED + COVERED))
if [ "$TOTAL" -eq 0 ]; then
    echo "Error: Total instructions is 0. Cannot calculate coverage."
    exit 1
fi

ACTUAL_COVERAGE=$(echo "scale=2; $COVERED * 100 / $TOTAL" | bc)
# Convert to integer for comparison
INT_COVERAGE=$(echo "$ACTUAL_COVERAGE/1" | bc)

echo "--------------------------------------------------------"
echo "Total Instructions: $TOTAL"
echo "Covered:            $COVERED"
echo "Missed:             $MISSED"
echo "Actual Coverage:    $ACTUAL_COVERAGE%"
echo "Threshold:          $THRESHOLD%"
echo "--------------------------------------------------------"

if [ "$INT_COVERAGE" -lt "$THRESHOLD" ]; then
    echo "FAILED: Coverage ($ACTUAL_COVERAGE%) is below threshold ($THRESHOLD%)!"
    exit 1
else
    echo "PASSED: Coverage ($ACTUAL_COVERAGE%) meets threshold."
    exit 0
fi
