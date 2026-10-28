from pydantic import BaseModel
from typing import List

class CategorizeRequest(BaseModel):
    description: str

class WageSuggestionRequest(BaseModel):
    skills: List[str]
    location: str

class WorkerMatchProfile(BaseModel):
    uid: str
    skillsList: List[str]
    averageRating: float
    latitude: float = 0.0
    longitude: float = 0.0

class MatchWorkerRequest(BaseModel):
    job_description: str
    job_latitude: float = 0.0
    job_longitude: float = 0.0
    workers: List[WorkerMatchProfile]
