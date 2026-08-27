# VSCode Tree-Sitter Integration Analysis

## Executive Summary

This PL/SQL tree-sitter grammar is **functionally complete for parsing** but **lacks the query files** needed for syntax highlighting in editors like VSCode, Neovim, and other tree-sitter-aware tools.

**Grammar Status:** ✅ Working (STATE_COUNT: 45,888 - within safe limits)
**Highlighting Support:** ❌ Missing (no `queries/` directory)

---

## What's Required for Full Tree-Sitter Support

### 1. Core Grammar Files ✅ PRESENT

- [x] **grammar.js** - Grammar definition with 144KB of PL/SQL rules
- [x] **src/parser.c** - Generated parser (42.1 MB)
- [x] **src/scanner.c** - Custom external scanner for keyword handling
- [x] **src/node-types.json** - 13,470 lines of node type definitions
- [x] **Cargo.toml** - Rust package configuration
- [x] **package.json** - Node.js package configuration
- [x] **bindings/** - Language bindings (Node.js, Rust)

### 2. Query Files ❌ MISSING

The `queries/` directory is **completely absent**. This directory should contain:

- [ ] **queries/highlights.scm** - Syntax highlighting rules (REQUIRED)
- [ ] **queries/injections.scm** - Language injection rules (for embedded SQL, etc.)
- [ ] **queries/locals.scm** - Scope and reference tracking
- [ ] **queries/indents.scm** - Indentation rules
- [ ] **queries/folds.scm** - Code folding rules
- [ ] **queries/tags.scm** - Symbol tagging for navigation

**Priority:** `highlights.scm` is the minimum requirement for syntax highlighting.

---

## How Tree-Sitter Works with Editors

### Modern VSCode Integration

1. **Native Tree-Sitter Support** (VSCode 1.67+)
   - VSCode can use tree-sitter grammars directly via extensions
   - Extensions declare grammar support in `package.json`
   - Query files define how syntax nodes map to highlight groups

2. **Neovim nvim-treesitter**
   - De facto standard for tree-sitter in editors
   - Requires `queries/highlights.scm` at minimum
   - Automatically discovers parsers and queries in `runtimepath`

3. **Legacy vscode-tree-sitter Extension** (Deprecated)
   - Original extension by georgewfraser
   - No longer maintained (deprecated 6+ years ago)
   - Modern LSP-based syntax coloring has superseded it

### Standard Highlight Captures

Query files use a capture syntax like `@keyword`, `@function`, `@string`. Common captures:

```scheme
; Keywords
@keyword
@keyword.control
@keyword.operator

; Functions
@function
@function.method
@function.builtin

; Variables & Identifiers
@variable
@variable.builtin
@property
@constant

; Types & Constructors
@type
@constructor

; Literals
@string
@number
@boolean
@constant.builtin

; Comments
@comment

; Operators & Punctuation
@operator
@punctuation.delimiter
@punctuation.bracket
```

---

## What's in Your Repo (Current State)

### ✅ Strong Points

1. **Comprehensive Grammar**
   - Extensive PL/SQL coverage (packages, object types, SQL features)
   - External scanner for keyword disambiguation
   - Handles real-world Oracle PL/SQL constructs
   - State count (45,888) is below the 48,000 safety threshold

2. **Proper Configuration**
   - `Cargo.toml` includes `"queries/*"` in package manifest
   - `tree-sitter.json` declares language scopes and file extensions
   - Multiple language bindings (Node.js, Rust)

3. **Documentation**
   - Comprehensive README with known gaps
   - Clear explanation of keyword handling approach
   - State budget monitoring guidance

### ❌ Missing Components

1. **No Query Files**
   - `queries/` directory doesn't exist
   - Cannot perform syntax highlighting in any editor
   - Cargo.toml expects this directory but it's absent

2. **No Examples**
   - No test files demonstrating the grammar
   - No sample PL/SQL code for validation

3. **No Integration Instructions**
   - No documentation on editor setup
   - No VSCode extension configuration example
   - No nvim-treesitter setup guide

---

## Action Plan: Adding Syntax Highlighting

### Phase 1: Create Basic Highlights (High Priority)

1. **Create queries directory**
   ```bash
   mkdir -p queries
   ```

2. **Create queries/highlights.scm** with mappings for:
   - Keywords (SELECT, FROM, WHERE, CREATE, PROCEDURE, FUNCTION, etc.)
   - Built-in types (VARCHAR2, NUMBER, DATE, etc.)
   - Operators (AND, OR, NOT, comparison operators)
   - Literals (strings, numbers, booleans)
   - Comments
   - Identifiers (functions, variables, tables)
   - Special nodes (labels, pragmas)

### Phase 2: Advanced Queries (Medium Priority)

3. **Create queries/injections.scm**
   - Handle embedded languages (SQL in PL/SQL blocks)
   - Mark string literals for potential injection

4. **Create queries/locals.scm**
   - Track variable declarations and scopes
   - Mark function/procedure definitions

5. **Create queries/indents.scm**
   - Define indentation increase/decrease rules
   - Handle BEGIN/END blocks

### Phase 3: Editor Integration (Lower Priority)

6. **Document Setup**
   - Write setup instructions for VSCode
   - Write setup instructions for Neovim
   - Add examples to README

7. **Create Extension** (Optional)
   - Package as VSCode extension
   - Publish to marketplace

---

## Technical Considerations

### Node Type Analysis

Your grammar generates 13,470 lines of node types, including:
- `kw_*` nodes for keywords
- `expression`, `statement` variants
- SQL-specific constructs (`accessible_by_clause`, `aggregate_function_argument`, etc.)

**All of these need to be mapped** in highlights.scm to appropriate capture groups.

### External Scanner Keywords (57 keywords)

These keywords use word-boundary checking and need special attention in highlights:
- `kw_loop`, `kw_set`, `kw_log`, `kw_replace`, `kw_forall`, `kw_save`, `kw_to`, `kw_row`, `kw_is`, etc.

### File Type Support

From `tree-sitter.json`:
```json
"file-types": ["pks", "pkb", "prc", "fct", "tps", "tpb", "trg"]
```

These file extensions need to be registered in any VSCode extension.

---

## Comparison with Complete Grammars

**tree-sitter-javascript** (reference example):
```
queries/
├── highlights.scm        (main highlighting)
├── highlights-jsx.scm    (JSX-specific)
├── highlights-params.scm (parameter highlighting)
├── injections.scm        (language injections)
├── locals.scm           (scope tracking)
└── tags.scm             (ctags-style tagging)
```

**Your grammar** should follow a similar structure, at minimum:
```
queries/
└── highlights.scm       (REQUIRED for any highlighting)
```

---

## Recommendations

### Immediate (Required)

1. **Create `queries/highlights.scm`** - This is the blocker for all syntax highlighting
2. **Test with tree-sitter CLI** - Run `tree-sitter highlight <test-file.sql>`
3. **Validate captures** - Use `tree-sitter highlight --check`

### Short Term (Recommended)

4. **Add sample PL/SQL files** - Create `test/` or `examples/` directory
5. **Document editor setup** - Add VSCode and Neovim setup to README
6. **Add injections.scm** - Support embedded SQL/PL/SQL contexts

### Long Term (Nice to Have)

7. **Create VSCode extension** - Package for marketplace distribution
8. **Add indents.scm** - Improve editor auto-indentation
9. **Add folds.scm** - Enable code folding on blocks
10. **Join nvim-treesitter** - Submit grammar for inclusion

---

## Example: Minimal highlights.scm Starter

```scheme
; Keywords
[
  "SELECT" "FROM" "WHERE" "INSERT" "UPDATE" "DELETE"
  "CREATE" "DROP" "ALTER" "TABLE" "VIEW" "INDEX"
  "PROCEDURE" "FUNCTION" "PACKAGE" "TRIGGER"
  "BEGIN" "END" "IF" "THEN" "ELSE" "ELSIF"
  "LOOP" "WHILE" "FOR" "EXIT" "CONTINUE"
  "DECLARE" "RETURN" "NULL" "IS" "AS"
] @keyword

; Types
[
  "VARCHAR2" "NUMBER" "DATE" "TIMESTAMP"
  "INTEGER" "BOOLEAN" "CLOB" "BLOB"
] @type.builtin

; Operators
[ "AND" "OR" "NOT" "IN" "BETWEEN" "LIKE" ] @keyword.operator

; Literals
(string_literal) @string
(numeric_literal) @number
(comment) @comment

; Functions
(function_call name: (identifier) @function)

; Identifiers
(identifier) @variable
```

This would need to be expanded to cover all the node types in your grammar.

---

## Conclusion

Your tree-sitter-plsql grammar is **parsing-ready** but **not editor-ready**. The core parsing infrastructure is solid and comprehensive, but without query files, it cannot provide syntax highlighting in modern editors.

**Estimated Effort to Fix:**
- Minimal viable highlights.scm: 4-8 hours
- Comprehensive highlights.scm: 16-24 hours
- Full query suite (all .scm files): 2-3 days

**Blocking Issue:** No `queries/` directory exists at all.

**Immediate Next Step:** Create `queries/highlights.scm` with mappings for your grammar's node types.
