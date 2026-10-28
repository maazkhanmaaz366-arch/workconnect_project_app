from fastapi import APIRouter
from .schemas import CategorizeRequest, WageSuggestionRequest, MatchWorkerRequest
from .services import categorize_job_text, suggest_fair_wage, score_workers

router = APIRouter(prefix="/ai", tags=["AI"])

@router.post("/categorize")
def categorize_job(request: CategorizeRequest):
    """
    Uses AI to extract the primary job category from a natural language description.
    """
    return categorize_job_text(request.description)

@router.post("/suggest-wage")
def suggest_wage(request: WageSuggestionRequest):
    """
    Uses AI to suggest a fair daily wage based on skills and location.
    """
    return suggest_fair_wage(request.skills, request.location)

@router.post("/match")
def match_workers(request: MatchWorkerRequest):
    """
    Uses AI to score a list of workers against a job description (0-100 match score).
    """
    return score_workers(request.job_description, request.job_latitude, request.job_longitude, [w.model_dump() for w in request.workers])
