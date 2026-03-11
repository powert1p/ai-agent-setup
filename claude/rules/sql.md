---
globs: "**/*.sql"
---

# SQL & Migrations Rules

## Numbering
- Files: `NNN_description.sql`
- Check last number in migrations/ before creating new

## Idempotency
- `CREATE TABLE IF NOT EXISTS`, `CREATE INDEX IF NOT EXISTS`
- `INSERT ... ON CONFLICT DO UPDATE` for reference data
- Migration must be safe for re-run

## Safety
- SQL in code ONLY parameterized. In migrations — literals OK
- No DROP TABLE/DROP COLUMN without explicit approval
- To delete — agree first, then write
