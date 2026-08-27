#!/bin/bash
################################################################################
# Script: check_parse_errors.sh
# Description: Parse all PL/SQL files in a directory tree and report errors
# Usage: ./check_parse_errors.sh [directory]
################################################################################

set -o pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default directory (can be overridden by command line argument)
TARGET_DIR="${1:-examples}"

# Check if directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${RED}Error: Directory '$TARGET_DIR' not found${NC}"
    exit 1
fi

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Tree-Sitter PL/SQL Parser Error Checker               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Scanning directory: ${TARGET_DIR}${NC}"
echo ""

# Find all SQL files (compatible with all shells)
SQL_FILES=()
while IFS= read -r file; do
    SQL_FILES+=("$file")
done < <(find "$TARGET_DIR" -type f \( -name "*.sql" -o -name "*.pks" -o -name "*.pkb" -o -name "*.prc" -o -name "*.fnc" -o -name "*.trg" \) | sort)

if [ ${#SQL_FILES[@]} -eq 0 ]; then
    echo -e "${YELLOW}No SQL files found in $TARGET_DIR${NC}"
    exit 0
fi

echo -e "${BLUE}Found ${#SQL_FILES[@]} files to parse${NC}"
echo ""

# Initialize counters
TOTAL_FILES=0
SUCCESS_COUNT=0
ERROR_COUNT=0
declare -a ERROR_FILES
declare -a ERROR_DETAILS

# Temporary file for parse output
TEMP_OUTPUT=$(mktemp)
trap "rm -f $TEMP_OUTPUT" EXIT

# Parse each file
for file in "${SQL_FILES[@]}"; do
    TOTAL_FILES=$((TOTAL_FILES + 1))
    
    # Get file size for statistics
    FILE_SIZE=$(wc -c < "$file" 2>/dev/null || echo "0")
    FILE_LINES=$(wc -l < "$file" 2>/dev/null || echo "0")
    
    # Parse the file and capture output (ignore exit code, check for ERROR in output)
    tree-sitter parse "$file" --quiet --stat > "$TEMP_OUTPUT" 2>&1
    
    # Check if parse was successful (no ERROR in output)
    if grep -q "ERROR" "$TEMP_OUTPUT"; then
        ERROR_COUNT=$((ERROR_COUNT + 1))
        ERROR_FILES+=("$file")
        
        # Extract error details from the summary line
        ERROR_INFO=$(grep "Parse:" "$TEMP_OUTPUT" | grep "ERROR" | sed 's/.*(/ERROR (/g' || echo "Parse error detected")
        ERROR_DETAILS+=("$ERROR_INFO")
        
        # Extract parse time
        PARSE_TIME=$(grep "Parse:" "$TEMP_OUTPUT" | awk '{print $2, $3}' || echo "N/A")
        
        echo -e "${RED}✗${NC} $(basename "$file") ${RED}[PARSE ERROR]${NC}"
        echo -e "  ${YELLOW}Lines: $FILE_LINES | Size: $(numfmt --to=iec-i --suffix=B $FILE_SIZE 2>/dev/null || echo "${FILE_SIZE}B") | Parse: $PARSE_TIME${NC}"
        echo -e "  ${RED}$ERROR_INFO${NC}"
    else
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        
        # Extract parse time if available
        PARSE_TIME=$(grep "Parse:" "$TEMP_OUTPUT" | awk '{print $2, $3}' || echo "N/A")
        
        echo -e "${GREEN}✓${NC} $(basename "$file") ${GREEN}[OK]${NC}"
        echo -e "  ${YELLOW}Lines: $FILE_LINES | Size: $(numfmt --to=iec-i --suffix=B $FILE_SIZE 2>/dev/null || echo "${FILE_SIZE}B") | Parse: $PARSE_TIME${NC}"
    fi
    echo ""
done

# Summary
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                         SUMMARY                                ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "Total files parsed:    ${BLUE}${TOTAL_FILES}${NC}"
echo -e "Successful parses:     ${GREEN}${SUCCESS_COUNT}${NC}"
echo -e "Failed parses:         ${RED}${ERROR_COUNT}${NC}"

if [ $ERROR_COUNT -gt 0 ]; then
    SUCCESS_RATE=$(awk "BEGIN {printf \"%.1f\", ($SUCCESS_COUNT / $TOTAL_FILES) * 100}")
else
    SUCCESS_RATE="100.0"
fi

echo -e "Success rate:          ${BLUE}${SUCCESS_RATE}%${NC}"
echo ""

# Detailed error report if there are errors
if [ $ERROR_COUNT -gt 0 ]; then
    echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}                     ERROR DETAILS                              ${NC}"
    echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    for i in "${!ERROR_FILES[@]}"; do
        echo -e "${RED}[$((i+1))/${ERROR_COUNT}]${NC} ${ERROR_FILES[$i]}"
        echo -e "     ${ERROR_DETAILS[$i]}"
        echo ""
    done
    
    exit 1
else
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}           ✓ All files parsed successfully! ✓                  ${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    exit 0
fi
