import os
from dotenv import load_dotenv
load_dotenv()

from fastapi.testclient import TestClient
from main import app
from unittest.mock import patch
import uuid

client = TestClient(app)

def test_entire_flow():
    print("--- STARTING FLOW SIMULATION ---")
    
    with patch("api.auth.services.auth.verify_id_token") as mock_verify, \
         patch("api.auth.services.auth.set_custom_user_claims") as mock_set_claims:
        
        # 1. Simulate Worker Auth
        worker_uid = str(uuid.uuid4())
        mock_verify.return_value = {"uid": worker_uid, "email": "worker@test.com"}
        resp = client.post("/auth/register", json={"id_token": "fake_token", "role": "worker"})
        print("\n1. Worker Auth:", resp.json())

        # 1. Simulate Employer Auth
        employer_uid = str(uuid.uuid4())
        mock_verify.return_value = {"uid": employer_uid, "email": "employer@test.com"}
        resp = client.post("/auth/register", json={"id_token": "fake_token", "role": "employer"})
        print("1b. Employer Auth:", resp.json())

    # 2. Worker creates profile
    worker_profile = {
        "name": "John Doe",
        "photoUrl": "http://example.com/photo.jpg",
        "skillsList": ["Plumbing", "Pipe Fitting"],
        "expectedWage": 1000,
        "latitude": 31.5204,
        "longitude": 74.3587
    }
    resp = client.post(f"/users/{worker_uid}/worker", json=worker_profile)
    print("\n2. Worker Profile Created:", resp.json())

    # 3. AI Suggests Wage
    resp = client.post("/ai/suggest-wage", json={"skills": ["Plumbing"], "location": "Lahore"})
    print("\n3. AI Wage Suggestion:", resp.json())

    # 4. Employer Posts Job (AI Auto-Categorizes)
    job_data = {
        "description": "Need a plumber to fix a leaking bathroom pipe immediately.",
        "employerId": employer_uid,
        "latitude": 31.5204,
        "longitude": 74.3587,
        "wageOffer": 1500
    }
    resp = client.post("/jobs/", json=job_data)
    print("\n4. Employer Posted Job (Categorized by AI):", resp.json())
    job_id = resp.json().get("jobId")

    # 5. AI Matching Workers
    workers_to_match = [{
        "uid": worker_uid,
        "skillsList": ["Plumbing", "Pipe Fitting"],
        "averageRating": 0.0
    }]
    resp = client.post("/ai/match", json={"job_description": job_data["description"], "workers": workers_to_match})
    print("\n5. AI Worker Match Scores:", resp.json())

    # 6. Employer Reviews Worker
    review_data = {
        "workerId": worker_uid,
        "employerId": employer_uid,
        "jobId": job_id,
        "rating": 5,
        "comment": "Great plumber, very fast!"
    }
    resp = client.post("/reviews/", json=review_data)
    print("\n6. Employer Review:", resp.json())

    # 7. Check Worker's new average rating
    resp = client.get(f"/users/{worker_uid}/worker")
    print("\n7. Updated Worker Profile (Check Rating):", resp.json())

    # 8. Worker Applies to Job
    app_data = {
        "workerId": worker_uid,
        "employerId": employer_uid
    }
    resp = client.post(f"/jobs/{job_id}/apply", json=app_data)
    print("\n8. Worker Applied to Job:", resp.json())

    # 9. Admin Manually Verifies Worker
    resp = client.patch(f"/users/{worker_uid}/verify", json={"isVerified": True})
    print("\n9. Admin Verifies Worker:", resp.json())

if __name__ == "__main__":
    test_entire_flow()
