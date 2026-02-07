import { compactDecrypt } from "jose";

/**
 * Middleware to verify JWE authentication token
 * 
 * SECURITY NOTES:
 * - Validates token structure (Bearer prefix)
 * - Decrypts JWE using A256KW + A256GCM (must match Python backend)
 * - Verifies token_type is "access" (prevents refresh token abuse)
 * - Checks expiration
 */
export const authMiddleware = async (req, res, next) => {
  // Skip authentication in development mode for testing
  if (process.env.NODE_ENV !== 'production') {
    console.log('[DEV] Skipping authentication in development mode');
    req.user = {
      user_id: 'dev-test-user',
      token_type: 'access',
      is_pro: true, // Grant Pro access in dev mode
    };
    return next();
  }

  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ error: "Authentication required" });
  }

  const token = authHeader.split(" ")[1];
  const secret = process.env.JWE_SECRET_KEY;

  if (!secret) {
    console.error("[SECURITY] JWE_SECRET_KEY is not defined in environment variables");
    return res.status(500).json({ error: "Server configuration error" });
  }

  try {
    // Pad or truncate secret to 32 bytes (must match Python's _get_jwe_key implementation)
    const keyBytes = new TextEncoder().encode(secret.padEnd(32, "\0").slice(0, 32));
    const { plaintext } = await compactDecrypt(token, keyBytes);
    const payload = JSON.parse(new TextDecoder().decode(plaintext));

    // Verify token type (prevent refresh token abuse)
    if (payload.token_type !== "access") {
      console.warn("[SECURITY] Non-access token used for API call:", payload.token_type);
      return res.status(401).json({ error: "Invalid token type" });
    }

    // Check expiration
    if (payload.exp && Date.now() / 1000 > payload.exp) {
      return res.status(401).json({ error: "Token expired" });
    }

    req.user = payload;
    next();
  } catch (error) {
    console.error("[SECURITY] JWE verification failed:", error.message);
    return res.status(401).json({ error: "Invalid token" });
  }
};
