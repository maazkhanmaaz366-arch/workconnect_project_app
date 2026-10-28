from fastapi import FastAPI, HTTPException, UploadFile, File
import firebase_admin
from firebase_admin import credentials, firestore

import os
import shutil
import uuid
from dotenv import load_dotenv

from api.auth.router import router as auth_router
from api.users.router import router as users_router
from api.jobs.router import router as jobs_router
from api.ai.router import router as ai_router
from api.reviews.router import router as reviews_router

load_dotenv()

print("\n================ PRODUCTION STARTUP CHECK ================")
api_key = os.environ.get("OPENROUTER_API_KEY")
if not api_key:
    print("CRITICAL ERROR: OPENROUTER_API_KEY missing from environment variables!")
else:
    print("SUCCESS: OpenRouter API Key Detected.")

if not firebase_admin._apps:
    try:
        key_path = os.path.join(os.path.dirname(__file__), "api", "workconnectfirebasekey.json")
        cred = credentials.Certificate(key_path)
        firebase_admin.initialize_app(cred)
        # Verify connection
        db = firestore.client()
        print("SUCCESS: Firebase Admin SDK securely connected.")
    except Exception as e:
        print(f"CRITICAL ERROR: Failed to connect to Firebase: {e}")
print("=========================================================\n")

from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="WorkConnect Production Backend API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from fastapi.staticfiles import StaticFiles

os.makedirs("uploads", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

from fastapi import Request

@app.post("/upload")
async def upload_image(request: Request, file: UploadFile = File(...)):
    try:
        ext = file.filename.split(".")[-1] if "." in file.filename else "jpg"
        filename = f"{uuid.uuid4()}.{ext}"
        filepath = os.path.join("uploads", filename)
        with open(filepath, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        base_url = str(request.base_url).rstrip("/")
        return {"url": f"{base_url}/uploads/{filename}"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

app.include_router(auth_router)
app.include_router(users_router)
app.include_router(jobs_router)
app.include_router(ai_router)
app.include_router(reviews_router)

@app.get("/")
def read_root():
    return {"message": "Welcome to WorkConnect API"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
