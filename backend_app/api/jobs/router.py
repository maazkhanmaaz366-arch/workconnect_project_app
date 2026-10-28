from fastapi import APIRouter
from .schemas import JobCreate, JobApplicationCreate
from .services import create_job, get_job, apply_to_job, get_all_jobs

router = APIRouter(prefix="/jobs", tags=["Jobs"])

@router.post("/")
def post_job(job: JobCreate):
    """
    Employers post a job here. The AI will automatically categorize it,
    and Push Notifications will be sent to nearby workers.
    """
    return create_job(job.model_dump())

@router.get("/{job_id}")
def read_job(job_id: str):
    """
    Fetches job details.
    """
    return get_job(job_id)

@router.post("/{job_id}/apply")
def submit_application(job_id: str, req: JobApplicationCreate):
    """
    Worker applies to a job, triggering a Push Notification to the employer.
    """
    return apply_to_job(job_id, req.model_dump())

@router.get("/")
def list_jobs(employer_id: str = None):
    """
    List jobs. If employer_id is provided, only lists their jobs.
    """
    return get_all_jobs(employer_id)
