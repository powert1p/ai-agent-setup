---
globs: "**/*.py"
---

# Python Backend Rules

## Architecture
- handler/router -> service/use-case -> repository/db
- Handler does NOT write SQL or contain business logic
- Service does NOT know about HTTP (no framework imports)
- Repository only works with DB

## SQL Safety
- ONLY parameterized SQL. Never f-string/concatenation
- FORBIDDEN: `f"SELECT ... WHERE id = {user_id}"`
- ORDER BY / LIMIT — via parameters or whitelist

## Pydantic
- Endpoints return typed Response schemas
- Secrets — SecretStr, not str
- Input validation via Pydantic at handler level

## Style
- Early return over nesting. Max 3 levels
- Comments in Russian
- Search existing utilities before writing new ones
- Don't add features beyond the task, don't refactor extra
