from fastapi import APIRouter
from .schemas import ReviewCreate
from .services import submit_review

router = APIRouter(prefix="/reviews", tags=["Reviews"])

@router.post("/")
def create_review(review: ReviewCreate):
    """
    Submits a rating for a worker. The system automatically recalculates
    their average score and grants them a Verified Badge if they qualify.
    """
    return submit_review(review.model_dump())
