from fastapi import APIRouter
from .schemas import RegisterRequest, GoogleOverrideRequest
from .services import register_user, override_google_login

router = APIRouter(prefix="/auth", tags=["Auth"])

@router.post("/register")
def register(request: RegisterRequest):
    """
    Registers a newly authenticated Firebase user in the system.
    Validates the Firebase ID token, sets the custom user claim for the role,
    and initializes the user's Firestore document.
    """
    result = register_user(request.id_token, request.role)
    return result

@router.post("/google-override")
def google_override(request: GoogleOverrideRequest):
    """
    Allows a user with an existing email/password account to login via Google
    by verifying the Google ID token and issuing a Custom Firebase Token.
    """
    return override_google_login(request.id_token)
