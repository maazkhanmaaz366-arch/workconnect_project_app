from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime

class UserBase(BaseModel):
    uid: str
    email: str
    role: str
    fullName: str
    phoneNumber: Optional[str] = ""
    profileImage: Optional[str] = ""
    createdAt: datetime = Field(default_factory=datetime.now)

class WorkerProfile(UserBase):
    skillsList: List[str] = []
    hourlyRate: float = 0.0
    professionalTitle: Optional[str] = ""
    bio: Optional[str] = ""
    portfolioUrls: List[str] = []
    averageRating: float = 0.0
    totalReviews: int = 0
    latitude: Optional[float] = 0.0
    longitude: Optional[float] = 0.0
    fcmToken: Optional[str] = ""

class EmployerProfile(UserBase):
    companyName: Optional[str] = ""
    industry: Optional[str] = ""
    companySize: Optional[str] = ""
    website: Optional[str] = ""
    location: Optional[str] = ""
    bio: Optional[str] = ""
    latitude: Optional[float] = 0.0
    longitude: Optional[float] = 0.0

class VerificationUpdate(BaseModel):
    isVerified: bool
