# Learnings

- Better Auth client can fetch provider OAuth access tokens post-login via `authClient.getAccessToken({ providerId })`.
- Provider selection can be inferred via `authClient.listAccounts()` and reading `providerId`.
- `authClient.getSession()` works well for a non-hook, async bridge that needs `session.user.email`/`name`.
- Backend JWT storage already exists in `apps/web/src/lib/api-client.ts` (localStorage + refresh interceptor), so the missing piece is a one-time OAuth→JWT exchange.
