import os

import requests


api_key = os.environ.get("FIREBASE_API_KEY")
email = os.environ.get("ADMIN_EMAIL")
password = os.environ.get("ADMIN_PASSWORD")

missing = [
    name
    for name, value in (
        ("FIREBASE_API_KEY", api_key),
        ("ADMIN_EMAIL", email),
        ("ADMIN_PASSWORD", password),
    )
    if not value
]
if missing:
    raise SystemExit(f"Set the required environment variables: {', '.join(missing)}")

url = f"https://identitytoolkit.googleapis.com/v1/accounts:signUp?key={api_key}"
response = requests.post(
    url,
    json={"email": email, "password": password, "returnSecureToken": True},
    timeout=20,
)

if not response.ok:
    raise RuntimeError(
        f"Firebase account creation failed (HTTP {response.status_code})."
    )

print("Firebase account creation succeeded.")
