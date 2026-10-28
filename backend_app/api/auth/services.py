from fastapi import HTTPException
from firebase_admin import auth, firestore
from datetime import datetime, timezone
import urllib.request
import json

def register_user(id_token: str, role: str):
    try:
        # Verify the ID token
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token.get("uid")
        email = decoded_token.get("email")

        if not uid:
            raise HTTPException(status_code=400, detail="Invalid token: No UID found.")

        # Set custom user claims for role-based access
        auth.set_custom_user_claims(uid, {"role": role})

        # Create user document in Firestore
        db = firestore.client()
        user_ref = db.collection("users").document(uid)
        
        # We use set with merge=True to ensure we don't wipe existing data if a user re-authenticates
        user_ref.set({
            "role": role,
            "email": email,
            "createdAt": datetime.now(timezone.utc).isoformat()
        }, merge=True)

        return {"uid": uid, "role": role, "message": "User registered successfully."}

    except auth.InvalidIdTokenError:
        raise HTTPException(status_code=401, detail="Invalid ID Token.")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def override_google_login(id_token: str):
    try:
        url = f"https://oauth2.googleapis.com/tokeninfo?id_token={id_token}"
        req = urllib.request.Request(url)
        try:
            with urllib.request.urlopen(req) as response:
                token_info = json.loads(response.read().decode())
        except urllib.error.HTTPError:
            raise HTTPException(status_code=401, detail="Invalid Google ID Token")
        
        email = token_info.get("email")
        if not email or token_info.get("email_verified") != "true":
            raise HTTPException(status_code=400, detail="Email not verified by Google")
            
        try:
            user = auth.get_user_by_email(email)
        except auth.UserNotFoundError:
            raise HTTPException(status_code=404, detail="User not found")
            
        custom_token = auth.create_custom_token(user.uid)
        return {"custom_token": custom_token.decode("utf-8") if isinstance(custom_token, bytes) else custom_token}
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
