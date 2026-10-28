from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime

class JobCreate(BaseModel):
    employerId: str
    title: str
    description: str
    category: Optional[str] = "General"
    location: Optional[str] = "Location Set"
    budget: float
    status: Optional[str] = "open"
    latitude: float
    longitude: float
    createdAt: datetime = Field(default_factory=datetime.now)
    applicants: List[str] = []

class JobApplicationCreate(BaseModel):
    workerId: str
    employerId: str
    jobId: str
