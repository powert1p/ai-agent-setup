---
globs: "**/*.{ts,tsx,jsx}"
---

# React/TypeScript Rules

## React Query (TanStack v5)
- GET: `useQuery({ queryKey, queryFn, staleTime: 5 * 60 * 1000 })`
- POST/PUT/DELETE: `useMutation({ mutationFn, onSuccess: invalidateQueries })`
- DON'T use useState+useEffect for data fetching — React Query only
- staleTime: 5 minutes default

## Tailwind CSS
- Only Tailwind classes. No CSS-in-JS, styled-components, inline styles
- Responsive: `sm:`, `md:`, `lg:` prefixes

## Components
- One component = one file. Max 150 lines
- If larger — split into subcomponents
- PascalCase for components, camelCase for functions

## Types
- TypeScript types MUST match backend Pydantic schemas
- No `any`. Don't know the type — check backend schema

## API
- Use project's API client. Don't create fetch/axios calls directly

## Frontend Verification (ОБЯЗАТЕЛЬНО после изменений)
После ЛЮБЫХ фронтенд-изменений агент ОБЯЗАН верифицировать через Playwright MCP:
1. Убедиться что dev-сервер запущен (`npm run dev` / `vite`)
2. `browser_navigate` → `http://localhost:5173` (или актуальный URL)
3. `browser_snapshot` — проверить что элементы на месте, нет ошибок рендера
4. `browser_take_screenshot` — визуально оценить результат
5. `browser_console_messages` — проверить нет ли ошибок в консоли
6. Если нашёл проблемы — ИСПРАВИТЬ и повторить проверку
7. НЕ говорить "готово" пока не верифицировал в браузере
8. В отчёте указать: что проверил, скриншот, найденные и исправленные проблемы
