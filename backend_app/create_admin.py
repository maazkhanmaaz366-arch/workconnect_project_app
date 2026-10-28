import os

import firebase_admin
from firebase_admin import auth, credentials


key_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
email = os.environ.get("ADMIN_EMAIL")
password = os.environ.get("ADMIN_PASSWORD")
name = os.environ.get("ADMIN_DISPLAY_NAME", "Admin")

missing = [
    variable
    for variable, value in (
        ("GOOGLE_APPLICATION_CREDENTIALS", key_path),
        ("ADMIN_EMAIL", email),
        ("ADMIN_PASSWORD", password),
    )
    if not value
]
if missing:
    raise SystemExit(f"Set the required environment variables: {', '.join(missing)}")

cred = credentials.Certificate(key_path)
firebase_admin.initialize_app(cred)

try:
    user = auth.create_user(email=email, password=password, display_name=name)
except auth.EmailAlreadyExistsError:
    user = auth.get_user_by_email(email)
    user = auth.update_user(user.uid, password=password, display_name=name)

auth.set_custom_user_claims(user.uid, {"role": "admin"})
print(f"Successfully granted admin privileges to {email}.")
