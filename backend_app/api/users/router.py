from fastapi import APIRouter
from .schemas import WorkerProfile, VerificationUpdate
from .services import create_or_update_worker, get_worker, update_verification_status, delete_user_entirely

router = APIRouter(prefix="/users", tags=["Users"])

@router.post("/{uid}/worker")
def update_worker_profile(uid: str, profile: WorkerProfile):
    """
    Creates or updates a worker's profile containing skills, photo, and wage.
    """
    return create_or_update_worker(uid, profile.model_dump())

@router.get("/{uid}/worker")
def read_worker_profile(uid: str):
    """
    Retrieves a worker's public profile.
    """
    return get_worker(uid)

@router.patch("/{uid}/verify")
def verify_worker(uid: str, req: VerificationUpdate):
    """Admin endpoint to manually verify or unverify a worker."""
    return update_verification_status(uid, req.isVerified)

@router.delete("/{uid}")
def remove_user(uid: str):
    """Admin endpoint to permanently delete a user."""
    return delete_user_entirely(uid)
