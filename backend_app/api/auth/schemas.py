from pydantic import BaseModel
from typing import Literal

class RegisterRequest(BaseModel):
    id_token: str
    role: Literal["worker", "employer", "admin"]

class GoogleOverrideRequest(BaseModel):
    id_token: str
