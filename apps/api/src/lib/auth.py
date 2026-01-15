import json
from collections.abc import Callable
from datetime import datetime, timedelta
from functools import wraps
from typing import Annotated, Any, Literal, cast

import httpx
from fastapi import Depends, HTTPException, Request, status
from jose import jwe
from jose.exceptions import JWEError
from pydantic import BaseModel

from src.lib.config import settings


class TokenPayload(BaseModel):
    """JWT/JWE token payload."""

    user_id: str
    token_type: Literal["access", "refresh"]
    exp: int
    iat: int


class TokenResponse(BaseModel):
    """Token response."""

    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class OAuthLoginRequest(BaseModel):
    """OAuth login request."""

    provider: Literal["google", "github", "facebook"]
    access_token: str
    email: str
    name: str | None = None


class RefreshTokenRequest(BaseModel):
    """Refresh token request."""

    refresh_token: str


class OAuthUserInfo(BaseModel):
    """OAuth user information from provider."""

    id: str
    email: str | None = None
    name: str | None = None
    image: str | None = None
    email_verified: bool = False


class CurrentUserInfo(BaseModel):
    """Current authenticated user info."""

    id: str
    email: str | None = None
    name: str | None = None
    image: str | None = None
    email_verified: bool = False


def create_access_token(user_id: str) -> str:
    """Create JWE access token."""
    now = datetime.utcnow()
    payload = {
        "user_id": user_id,
        "token_type": "access",
        "exp": int((now + timedelta(hours=1)).timestamp()),
        "iat": int(now.timestamp()),
    }
    encrypted = jwe.encrypt(
        json.dumps(payload).encode(),
        settings.JWE_SECRET_KEY,
        algorithm="A256GCM",
        encryption="A256GCM",
    )
    if isinstance(encrypted, bytes):
        return encrypted.decode()
    return cast(str, encrypted)


def create_refresh_token(user_id: str) -> str:
    """Create JWE refresh token."""
    now = datetime.utcnow()
    payload = {
        "user_id": user_id,
        "token_type": "refresh",
        "exp": int((now + timedelta(days=7)).timestamp()),
        "iat": int(now.timestamp()),
    }
    encrypted = jwe.encrypt(
        json.dumps(payload).encode(),
        settings.JWE_SECRET_KEY,
        algorithm="A256GCM",
        encryption="A256GCM",
    )
    if isinstance(encrypted, bytes):
        return encrypted.decode()
    return cast(str, encrypted)


def decode_token(token: str) -> TokenPayload:
    """Decode and validate JWE token."""
    try:
        decrypted = jwe.decrypt(token, settings.JWE_SECRET_KEY)
        if decrypted is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token",
                headers={"WWW-Authenticate": "Bearer"},
            )
        payload = json.loads(decrypted.decode())
        return TokenPayload(**payload)
    except JWEError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
            headers={"WWW-Authenticate": "Bearer"},
        )


async def verify_google_token(access_token: str) -> OAuthUserInfo:
    """Verify Google OAuth token."""
    async with httpx.AsyncClient() as client:
        response = await client.get(
            "https://www.googleapis.com/oauth2/v3/userinfo",
            headers={"Authorization": f"Bearer {access_token}"},
            timeout=5.0,
        )
        if response.status_code != 200:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid Google access token",
            )
        data = response.json()
        return OAuthUserInfo(
            id=data["sub"],
            email=data["email"],
            name=data.get("name"),
            image=data.get("picture"),
            email_verified=data.get("email_verified", False),
        )


async def verify_github_token(access_token: str) -> OAuthUserInfo:
    """Verify GitHub OAuth token."""
    async with httpx.AsyncClient() as client:
        response = await client.get(
            "https://api.github.com/user",
            headers={"Authorization": f"Bearer {access_token}"},
            timeout=5.0,
        )
        if response.status_code != 200:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid GitHub access token",
            )
        data = response.json()
        return OAuthUserInfo(
            id=str(data["id"]),
            email=data.get("email"),
            name=data.get("name"),
            image=data.get("avatar_url"),
        )


async def verify_facebook_token(access_token: str) -> OAuthUserInfo:
    """Verify Facebook OAuth token."""
    async with httpx.AsyncClient() as client:
        response = await client.get(
            "https://graph.facebook.com/me?fields=id,email,name,picture",
            headers={"Authorization": f"Bearer {access_token}"},
            timeout=5.0,
        )
        if response.status_code != 200:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid Facebook access token",
            )
        data = response.json()
        picture_url = data.get("picture", {}).get("data", {}).get("url")
        return OAuthUserInfo(
            id=data["id"],
            email=data.get("email"),
            name=data.get("name"),
            image=picture_url,
        )


async def verify_oauth_token(provider: str, access_token: str) -> OAuthUserInfo:
    """Verify OAuth token based on provider."""
    if provider == "google":
        return await verify_google_token(access_token)
    elif provider == "github":
        return await verify_github_token(access_token)
    elif provider == "facebook":
        return await verify_facebook_token(access_token)
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unsupported provider: {provider}",
        )


async def get_current_user(request: Request) -> CurrentUserInfo:
    """Get current authenticated user from Authorization header."""
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = auth_header.replace("Bearer ", "")
    payload = decode_token(token)

    if payload.token_type != "access":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token type",
        )

    if datetime.utcnow().timestamp() > payload.exp:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token expired",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return CurrentUserInfo(id=payload.user_id)


async def get_optional_user(request: Request) -> CurrentUserInfo | None:
    """Get current user if authenticated, otherwise None."""
    try:
        return await get_current_user(request)
    except HTTPException:
        return None


CurrentUser = Annotated[CurrentUserInfo, Depends(get_current_user)]
OptionalUser = Annotated[CurrentUserInfo | None, Depends(get_optional_user)]


def require_auth(
    func: Callable[..., Any] | None = None,
) -> Callable[..., Any]:
    """Decorator to require authentication on a route.

    Usage:
        @router.get("/protected")
        @require_auth
        async def protected_route(user: CurrentUser):
            return {"user": user}
    """

    def decorator(f: Callable[..., Any]) -> Callable[..., Any]:
        @wraps(f)
        async def wrapper(*args: Any, **kwargs: Any) -> Any:
            return await f(*args, **kwargs)

        return wrapper

    if func is not None:
        return decorator(func)
    return decorator
