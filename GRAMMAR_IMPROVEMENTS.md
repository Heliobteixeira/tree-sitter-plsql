# Grammar Improvements - Oracle JSON Function Support

## Summary

Added support for Oracle 21c+ JSON functions to the PL/SQL grammar, improving package parse success rate from **27.3% (3/11)** to **45.5% (5/11)** on test corpus.

## What Was Implemented

### ✅ JSON_OBJECT Function
- **Syntax**: `JSON_OBJECT('key' VALUE expr, ... [RETURNING type])`
- **Grammar Rule**: `json_object_expression` at precedence 8 in `_expression_base_elements`
- **Components**:
  - `json_object_item`: Supports both `'string' VALUE expr` and `KEY identifier VALUE expr` patterns
  - Optional `RETURNING datatype` clause
- **Keywords Added**: `kw_json_object`, `kw_value` (already existed)

### ✅ JSON_ARRAYAGG Function
- **Syntax**: `JSON_ARRAYAGG(expr [ORDER BY ...] [RETURNING type])`
- **Grammar Rule**: `json_arrayagg_expression` at precedence 8
- **Features**:
  - Reuses existing `order_by_clause` rule
  - Optional `RETURNING datatype` clause
- **Keywords Added**: `kw_json_arrayagg`

### ✅ RETURNING INTO Collection Elements (Partial)
- **Syntax**: `RETURNING expr INTO record.collection(index).field`
- **Grammar Change**: Modified `_returning_clause` to accept `choice($.referenced_element, $.ref_call)` for INTO targets
- **Status**: Partially working - fixes first occurrences but files with multiple such constructs still fail

## Parse Results

Tested on corpus of 11 enterprise PL/SQL package files (totaling ~47,000 lines):

### Successfully Parsing: 5/11 packages (45.5%)
- 3 packages were already parsing correctly before changes
- 2 additional packages now parse successfully with JSON support (**FIXED**)

### Still Failing: 6/11 packages (54.5%)
| Root Cause | Count | Details |
|------------|------:|---------|
| `ABSENT ON NULL` clause not supported | 3 | Parser size limit exceeded |
| `XMLQUERY` function not supported | 1 | Parser size limit exceeded |
| Complex patterns | 2 | Multiple advanced constructs |

## Known Limitations

### ❌ ABSENT ON NULL / NULL ON NULL Clauses
**Reason**: Adding these optional clauses causes parse table action count to exceed tree-sitter's hard limit of 65,535.

**Impact**: 3 packages fail (27.3% of total)

**Attempted Solutions**:
- Treating as `optional(choice(...))` → 67,642 actions (failed)
- Treating as `optional(seq($.kw_absent, ...))` → 67,642 actions (failed)
- Treating ABSENT as identifier → 78,618 actions (worse!)

**Workaround**: None possible without reducing grammar complexity elsewhere

### ❌ XMLQUERY and XMLCAST Functions
**Reason**: Adding these functions pushes parse table over the limit.

**Impact**: 1 package fails (uses XMLQUERY with XQuery expressions)

**Attempted Solutions**:
- Full XMLQUERY with optional PASSING/RETURNING → 75,247 actions (failed)
- Simplified XMLQUERY → 67,254 actions (failed)
- Including XMLCAST → exceeded limits

**Workaround**: Could be implemented if JSON support is removed, but JSON is higher priority (affects more files)

### ⚠️ Multiple RETURNING INTO Collection Patterns
**Status**: Partially working

**Impact**: Some files with multiple complex RETURNING clauses still fail

**Cause**: Unknown - possibly hitting another grammar limitation or interaction with other constructs

## Technical Details

### Grammar Size Constraints
The tree-sitter parser has a hard limit:
- **Parse table action count**: Maximum 65,535
- **Current baseline** (before changes): ~64,000 actions
- **After JSON additions**: ~65,000 actions (very close to limit)

This means **no additional expression-level rules can be added** without removing existing functionality.

### Implementation Approach
Following existing patterns:
- **Reference**: XMLFOREST/XMLELEMENT (lines 2097-2185 in grammar.js)
- **Location**: Added to `_expression_base_elements` at precedence 8
- **Style**: Used explicit `seq()` rules, avoided excessive `optional()` and `choice()` nesting

### Files Modified
- [`grammar.js`](grammar.js):
  - Added `json_object_expression` rule (line ~2106)
  - Added `json_arrayagg_expression` rule (line ~2113)
  - Added `json_object_item` helper rule (line ~3222)
  - Modified `_returning_clause` to support `ref_call` (line ~1831)
  - Added keywords `kw_json_object`, `kw_json_arrayagg`, `kw_absent` (line ~4034)

## Recommendations

### Short Term
1. **Accept current limitations**: 45.5% success rate is a significant improvement
2. **Document workarounds**: Users needing ABSENT ON NULL can remove it manually
3. **Test on more diverse corpus**: Current 11 packages may not represent all usage patterns

### Long Term
1. **Grammar optimization**: Investigate reducing complexity in other areas to free up space for:
   - ABSENT ON NULL support
   - XMLQUERY support
   - Additional JSON functions (JSON_ARRAY, JSON_MERGEPATCH)

2. **Split grammar**: Consider creating a separate "Oracle SQL" grammar that focuses on SQL-specific constructs, leaving PL/SQL grammar for procedural code

3. **Upstream tree-sitter**: Investigate if tree-sitter's 65K action limit can be increased

## Testing

### Automated Test
```bash
./scripts/check_parse_errors.sh examples
```

### Individual Package Test
```bash
tree-sitter parse examples/your_package.sql --quiet --stat
```

### Regression Check
All 3 previously successful packages still parse correctly after changes, confirming no regressions were introduced.

## Related Files
- [VSCODE_INTEGRATION_ANALYSIS.md](VSCODE_INTEGRATION_ANALYSIS.md) - Missing syntax highlighting investigation
- [examples/README.md](examples/README.md) - Test corpus documentation
- [scripts/check_parse_errors.sh](scripts/check_parse_errors.sh) - Validation script

## References
- Oracle SQL Language Reference 21c - JSON Functions chapter
- Tree-sitter Grammar Development Guide
- Existing grammar patterns: XMLFOREST, LISTAGG, aggregate functions
