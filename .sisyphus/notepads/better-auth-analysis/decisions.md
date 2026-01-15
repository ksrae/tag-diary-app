# Decisions

- Keep Better Auth server configuration in `apps/web/src/lib/auth.ts` as the only `auth` export (Next.js route handler depends on it).
- Keep Better Auth React client in `apps/web/src/lib/auth-client.ts` as `authClient` (no `auth` export) to avoid naming collisions and keep concerns clear.
- Implement a small client-side bridge that, once a Better Auth session exists, exchanges the provider access token for backend JWTs via `POST /api/auth/login`, then stores them via `setAccessToken`/`setRefreshToken`.
- Mount the bridge once globally in `apps/web/src/app/providers.tsx` so existing pages don’t need to remember to do token exchange.
