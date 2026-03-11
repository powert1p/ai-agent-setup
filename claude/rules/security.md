---
globs: "**/api/**/*.py,**/routes/**/*.py,**/routers/**/*.py"
---

# API Security Rules

## SQL Injection
- ONLY parameterized queries
- FORBIDDEN: f-string, string concatenation in SQL
- ORDER BY / LIMIT — via parameters or whitelist

## Authentication
- JWT/auth checked on every protected endpoint
- No TODO/stubs in auth — do it now or don't merge
- Verify token type (access vs refresh)

## Secrets
- Only from env variables (Pydantic SecretStr)
- Never in code, comments, logs
- Don't log tokens, passwords, personal data

## Input Validation
- Pydantic schemas for all incoming data
- Limit page_size (max 100)

## Errors
- Don't return stack traces in production
- Don't swallow auth errors — always 401/403
- Log unauthorized access attempts
