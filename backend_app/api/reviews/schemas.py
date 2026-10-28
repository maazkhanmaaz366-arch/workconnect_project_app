from pydantic import BaseModel

class ReviewCreate(BaseModel):
    workerId: str
    employerId: str
    jobId: str
    rating: int  # Should be 1 to 5
    comment: str
