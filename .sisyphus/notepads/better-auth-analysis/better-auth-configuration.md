# Better Auth Configuration Analysis

## Overview
Better Auth v1.4.10 is configured as the authentication system for the fullstack starter. It handles OAuth/social provider authentication and session management across the web frontend and FastAPI backend.

---

## 1. Better Auth Configuration Files

### Location: `apps/web/src/lib/auth.ts`
**Server-side Better Auth initialization**

```typescript
import { betterAuth } from "better-auth";
import { nextCookies } from "better-auth/next-js";
import { env } from "@/config/env";

export const auth = betterAuth({
  baseURL: env.BETTER_AUTH_URL,
  secret: env.BETTER_AUTH_SECRET,
  socialProviders: {
    google: env.GOOGLE_CLIENT_ID
      ? {
          clientId: env.GOOGLE_CLIENT_ID,
          clientSecret: env.GOOGLE_CLIENT_SECRET,
        }
      : undefined,
    github: env.GITHUB_CLIENT_ID
      ? {
          clientId: env.GITHUB_CLIENT_ID,
          clientSecret: env.GITHUB_CLIENT_SECRET,
        }
      : undefined,
    facebook: env.FACEBOOK_CLIENT_ID
      ? {
          clientId: env.FACEBOOK_CLIENT_ID,
          clientSecret: env.FACEBOOK_CLIENT_SECRET,
        }
      : undefined,
  },
  plugins: [nextCookies()],
  session: {
    expiresIn: 60 * 60 * 24 * 7,  // 7 days
    cookieCache: {
      enabled: true,
      strategy: "jwe",  // JSON Web Encryption
    },
  },
  trustedOrigins: [env.BETTER_AUTH_URL],
});
```

**Key Configuration Details:**
- **Base URL**: Points to the Next.js app (default: `http://localhost:3000`)
- **Secret**: Minimum 32 characters for session encryption
- **Session Duration**: 7 days
- **Cookie Strategy**: JWE (JSON Web Encryption) for secure session storage
- **Trusted Origins**: Only the Better Auth URL is trusted

### Location: `apps/web/src/lib/auth-client.ts`
**Client-side Better Auth client**

```typescript
import { createAuthClient } from "better-auth/react";
import { env } from "@/config/env";

export const authClient = createAuthClient({
  baseURL: env.NEXT_PUBLIC_BETTER_AUTH_URL,
});

export const { useSession, signIn, signOut } = authClient;
```

**Exports:**
- `useSession`: React hook to get current session
- `signIn`: Function to initiate sign-in (OAuth or email/password)
- `signOut`: Function to sign out

### Location: `apps/web/src/app/api/auth/[...all]/route.ts`
**Next.js API route handler for Better Auth**

```typescript
import { toNextJsHandler } from "better-auth/next-js";
import { auth } from "@/lib/auth";

export const { GET, POST } = toNextJsHandler(auth.handler);
```

**Purpose:** Routes all `/api/auth/*` requests to Better Auth handler

---

## 2. Social Providers Configuration

### Configured Providers
1. **Google OAuth**
   - Client ID: `GOOGLE_CLIENT_ID`
   - Client Secret: `GOOGLE_CLIENT_SECRET`
   - Status: Optional (only enabled if credentials provided)

2. **GitHub OAuth**
   - Client ID: `GITHUB_CLIENT_ID`
   - Client Secret: `GITHUB_CLIENT_SECRET`
   - Status: Optional (only enabled if credentials provided)

3. **Facebook OAuth**
   - Client ID: `FACEBOOK_CLIENT_ID`
   - Client Secret: `FACEBOOK_CLIENT_SECRET`
   - Status: Optional (only enabled if credentials provided)

### ⚠️ Kakao OAuth NOT Configured
**Important Finding:** Kakao OAuth provider is **NOT currently configured** in the Better Auth setup. The configuration only includes Google, GitHub, and Facebook.

To add Kakao support, the following would need to be added to `auth.ts`:
```typescript
kakao: env.KAKAO_CLIENT_ID
  ? {
      clientId: env.KAKAO_CLIENT_ID,
      clientSecret: env.KAKAO_CLIENT_SECRET,
    }
  : undefined,
```

---

## 3. Environment Variables

### Location: `apps/web/src/config/env.ts`
**Environment configuration with Zod validation**

**Server-side variables:**
- `BETTER_AUTH_SECRET`: Required, minimum 32 characters
- `BETTER_AUTH_URL`: Optional, defaults to `http://localhost:3000`
- `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`: Optional
- `GITHUB_CLIENT_ID`, `GITHUB_CLIENT_SECRET`: Optional
- `FACEBOOK_CLIENT_ID`, `FACEBOOK_CLIENT_SECRET`: Optional

**Client-side variables (NEXT_PUBLIC_):**
- `NEXT_PUBLIC_BETTER_AUTH_URL`: Optional, defaults to `http://localhost:3000`
- `NEXT_PUBLIC_API_URL`: Optional, defaults to `http://localhost:8000`

### Location: `apps/web/.env.example`
```
# Auth
BETTER_AUTH_SECRET=your-secret-key-at-least-32-characters-long
BETTER_AUTH_URL=http://localhost:3000
NEXT_PUBLIC_BETTER_AUTH_URL=http://localhost:3000

# API
NEXT_PUBLIC_API_URL=http://localhost:8000

# OAuth - Google
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=

# OAuth - GitHub
GITHUB_CLIENT_ID=
GITHUB_CLIENT_SECRET=

# OAuth - Facebook
FACEBOOK_CLIENT_ID=
FACEBOOK_CLIENT_SECRET=
```

---

## 4. How Better Auth Generates Access Tokens

### Session Token Generation
Better Auth generates **session tokens** (not OAuth access_tokens) through:

1. **OAuth Flow:**
   - User clicks "Sign in with [Provider]"
   - Redirected to OAuth provider (Google/GitHub/Facebook)
   - Provider returns authorization code
   - Better Auth exchanges code for OAuth tokens
   - Better Auth creates a **session** for the user

2. **Session Token Storage:**
   - Token stored in **JWE-encrypted cookie** (secure, httpOnly)
   - Cookie name: `better-auth.session_token` (default)
   - Expires in 7 days
   - Automatically sent with requests

3. **Token Structure:**
   - Contains user ID, session ID, and expiration
   - Encrypted with `BETTER_AUTH_SECRET`
   - Validated on each request

### OAuth Provider Access Tokens
- **Stored in Better Auth database** (not exposed to frontend)
- Used by Better Auth to refresh user profile data
- **NOT directly accessible** from client-side code
- Better Auth manages token refresh automatically

---

## 5. Integration with Backend API

### Web Frontend → Backend Flow

**Location: `apps/web/src/lib/api-client.ts`**
```typescript
import axios from "axios";
import { env } from "@/config/env";

export const apiClient = axios.create({
  baseURL: env.NEXT_PUBLIC_API_URL,
  timeout: 30000,
  headers: {
    "Content-Type": "application/json",
  },
  withCredentials: true,  // ← Sends cookies with requests
});

apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      if (typeof window !== "undefined") {
        window.location.href = "/login";
      }
    }
    return Promise.reject(error);
  }
);
```

**Key Points:**
- `withCredentials: true` sends Better Auth session cookie with API requests
- 401 errors redirect to login page
- No manual token passing needed (cookie-based auth)

### Backend API Session Validation

**Location: `apps/api/src/lib/auth.py`**

```python
async def get_session(request: Request) -> SessionResponse | None:
    """Validate session with better-auth server.
    
    This calls the better-auth server to validate the session cookie.
    """
    cookies = request.cookies
    if not cookies:
        return None

    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{settings.BETTER_AUTH_URL}/api/auth/get-session",
                cookies=dict(cookies),
                timeout=5.0,
            )
            if response.status_code != 200:
                return None

            data = response.json()
            if not data or not data.get("session"):
                return None

            return SessionResponse(**data)
        except (httpx.RequestError, Exception):
            return None
```

**Session Validation Flow:**
1. Frontend sends request with Better Auth session cookie
2. Backend receives request with cookies
3. Backend calls `BETTER_AUTH_URL/api/auth/get-session` with cookies
4. Better Auth validates and returns session + user data
5. Backend uses session data for authorization

### Backend Configuration

**Location: `apps/api/src/lib/config.py`**
```python
# Auth (better-auth)
BETTER_AUTH_URL: str = "http://localhost:3000"
```

**Location: `apps/api/.env.example`**
```
BETTER_AUTH_URL=http://localhost:3000
```

---

## 6. Authentication Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    OAuth Sign-In Flow                            │
└─────────────────────────────────────────────────────────────────┘

1. User clicks "Sign in with Google"
   ↓
2. Frontend calls: authClient.signIn("google")
   ↓
3. Redirects to: /api/auth/signin/google
   ↓
4. Better Auth redirects to Google OAuth
   ↓
5. User authorizes app
   ↓
6. Google redirects back with auth code
   ↓
7. Better Auth exchanges code for tokens
   ↓
8. Better Auth creates session
   ↓
9. Session token stored in JWE-encrypted cookie
   ↓
10. User redirected to app (authenticated)

┌─────────────────────────────────────────────────────────────────┐
│                    API Request Flow                              │
└─────────────────────────────────────────────────────────────────┘

Frontend Request:
  GET /api/users
  Cookie: better-auth.session_token=<encrypted>
  ↓
Backend receives request
  ↓
Backend calls: GET http://localhost:3000/api/auth/get-session
  Cookie: better-auth.session_token=<encrypted>
  ↓
Better Auth validates cookie
  ↓
Returns: { session: {...}, user: {...} }
  ↓
Backend uses user data for authorization
  ↓
Returns protected resource
```

---

## 7. Key Files Summary

| File | Purpose | Type |
|------|---------|------|
| `apps/web/src/lib/auth.ts` | Server-side Better Auth config | Config |
| `apps/web/src/lib/auth-client.ts` | Client-side auth client | Client |
| `apps/web/src/app/api/auth/[...all]/route.ts` | API route handler | Handler |
| `apps/web/src/config/env.ts` | Environment validation | Config |
| `apps/api/src/lib/auth.py` | Backend session validation | Utility |
| `apps/api/src/lib/config.py` | Backend config | Config |

---

## 8. Important Notes

### ✅ What Works
- OAuth sign-in with Google, GitHub, Facebook
- Session-based authentication (cookie)
- Automatic session validation on backend
- 401 error handling with redirect to login
- 7-day session expiration

### ⚠️ Limitations
- **Kakao OAuth not configured** (would need to be added)
- OAuth provider access_tokens not exposed to frontend
- Session validation requires backend call to Better Auth
- No refresh token mechanism (relies on cookie expiration)

### 🔒 Security Features
- JWE encryption for session cookies
- httpOnly cookies (not accessible via JavaScript)
- Secure cookie transmission (withCredentials)
- Session validation on every API request
- Trusted origins validation

---

## 9. Adding Kakao OAuth Support

To add Kakao OAuth provider:

1. **Update `apps/web/src/lib/auth.ts`:**
   ```typescript
   kakao: env.KAKAO_CLIENT_ID
     ? {
         clientId: env.KAKAO_CLIENT_ID,
         clientSecret: env.KAKAO_CLIENT_SECRET,
       }
     : undefined,
   ```

2. **Update `apps/web/src/config/env.ts`:**
   ```typescript
   KAKAO_CLIENT_ID: z.string().optional().or(z.literal("")),
   KAKAO_CLIENT_SECRET: z.string().optional().or(z.literal("")),
   ```

3. **Update `.env.example`:**
   ```
   # OAuth - Kakao
   KAKAO_CLIENT_ID=
   KAKAO_CLIENT_SECRET=
   ```

4. **Verify Better Auth supports Kakao** (check better-auth v1.4.10 documentation)

---

## 10. Version Information

- **Better Auth Version**: 1.4.10
- **Next.js Version**: 16.1.1
- **FastAPI Backend**: Python 3.12
- **Session Duration**: 7 days
- **Cookie Encryption**: JWE (JSON Web Encryption)
