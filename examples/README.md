# PL/SQL Examples Directory

This directory contains real-world Oracle PL/SQL examples from enterprise applications, covering all major object types.

## Overview

**Note:** Example files are excluded from the repository via `.gitignore` as they contain proprietary code.

Place your own PL/SQL files here for testing purposes. The parser supports:

## Supported Object Types

### Package Specifications & Bodies
Enterprise packages with complex business logic, procedures, and functions

### Functions
Standalone functions with various return types:
- Regular functions
- Pipelined table functions
- Aggregate functions

### Procedures
Standalone procedures for business logic

### Object Types
Complex object type definitions with attributes and methods

### Type Bodies
Object type implementations with member functions and procedures

### Views
Analytical views with:
- Common Table Expressions (CTEs)
- Window functions
- Complex joins

### Tables
Table definitions with:
- Constraints (PRIMARY KEY, FOREIGN KEY, CHECK, UNIQUE)
- Indexes
- Partitioning clauses

### Sequences
Sequence generators for primary keys

### Triggers
Database triggers:
- DML triggers (BEFORE/AFTER INSERT/UPDATE/DELETE)
- INSTEAD OF triggers
- Compound triggers
- System triggers

## Use Cases

### For Highlight Query Development
Use these files to:
- Identify all node types your grammar produces
- Test capture patterns against real code
- Verify coverage of edge cases

### For Parser Testing
- Stress test with large files
- Validate various PL/SQL constructs
- Test performance and memory usage

### For Playground Exploration
```bash
tree-sitter playground
# Then copy/paste code from any example file
```

### For CLI Highlighting
```bash
tree-sitter highlight examples/your_file.sql
```

## File Naming Convention

Suggested prefixes for easy identification:
- `PACKAGENAME.sql` - Package specs/bodies
- `func_*.sql` - Functions
- `proc_*.sql` - Procedures
- `type_*.sql` - Object type definitions
- `typebody_*.sql` - Object type bodies
- `view_*.sql` - Views
- `table_*.sql` - Tables
- `seq_*.sql` - Sequences

## PL/SQL Features to Test

Your example files should ideally demonstrate:
- ✅ Package specifications and bodies
- ✅ Standalone functions (including PIPELINED)
- ✅ Standalone procedures
- ✅ Object types (with UNDER inheritance)
- ✅ Type bodies with member functions
- ✅ Complex views (WITH clauses, joins, analytics)
- ✅ Table definitions (constraints, indexes, partitions)
- ✅ Sequences
- ✅ Triggers (DML triggers)
- ✅ Dynamic SQL
- ✅ Bulk operations (FORALL, BULK COLLECT)
- ✅ Exception handling
- ✅ Nested subqueries
- ✅ Analytic functions
- ✅ JSON operations (JSON_OBJECT, JSON_ARRAYAGG)
- ✅ XML operations (XMLELEMENT, XMLAGG)
- ✅ Collections (nested tables, varrays)
- ✅ Record types
- ✅ Cursor operations
- ✅ Pragma directives

## Testing Your Files

Use the provided validation script to check parse success:
```bash
./scripts/check_parse_errors.sh examples
```
