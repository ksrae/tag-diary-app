# Problems / Follow-ups

- `apps/web/src/lib/api-client.ts` redirects to `/login` on missing/invalid refresh token, but there is currently no `/login` route implemented in `apps/web/src/app` (route group `(auth)` is empty). This isn’t introduced by the auth bridge, but it will matter once auth is wired into UI.
