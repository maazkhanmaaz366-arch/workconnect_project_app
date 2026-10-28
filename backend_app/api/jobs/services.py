from fastapi import HTTPException
from firebase_admin import firestore
from datetime import datetime, timezone
import uuid
from api.ai.services import categorize_job_text
from api.notifications.services import send_push_notification

def create_job(job_data: dict):
    try:
        category_result = categorize_job_text(job_data["description"])
        category = category_result.get("category", "General")

        job_id = str(uuid.uuid4())
        job_data["id"] = job_id
        job_data["category"] = category
        job_data["status"] = "open"
        job_data["timestamp"] = firestore.SERVER_TIMESTAMP

        db = firestore.client()
        db.collection("jobs").document(job_id).set(job_data)

        # Trigger push notification to nearby workers (simplified)
        workers_ref = db.collection("workers").stream()
        for worker in workers_ref:
            worker_data = worker.to_dict()
            if "fcmToken" in worker_data and worker_data["fcmToken"]:
                send_push_notification(
                    token=worker_data["fcmToken"],
                    title="New Job Nearby!",
                    body=f"A new {category} job was posted near you.",
                    data={"jobId": job_id}
                )

        return {"jobId": job_id, "category": category, "message": "Job posted successfully."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def get_job(job_id: str):
    try:
        db = firestore.client()
        job_doc = db.collection("jobs").document(job_id).get()
        if not job_doc.exists:
            raise HTTPException(status_code=404, detail="Job not found.")
        return job_doc.to_dict()
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def apply_to_job(job_id: str, app_data: dict):
    try:
        db = firestore.client()
        app_id = str(uuid.uuid4())
        application_data = {
            "applicationId": app_id,
            "jobId": job_id,
            "workerId": app_data["workerId"],
            "status": "pending",
            "timestamp": firestore.SERVER_TIMESTAMP
        }
        
        db.collection("applications").document(app_id).set(application_data)
        
        # Notify Employer
        employer_doc = db.collection("users").document(app_data["employerId"]).get()
        if employer_doc.exists:
            fcm_token = employer_doc.to_dict().get("fcmToken")
            if fcm_token:
                send_push_notification(
                    token=fcm_token,
                    title="New Job Application!",
                    body="A worker has applied to your job. Tap to view.",
                    data={"jobId": job_id, "applicationId": app_id}
                )

        return {"applicationId": app_id, "message": "Applied successfully."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def get_all_jobs(employer_id: str = None):
    try:
        db = firestore.client()
        query = db.collection("jobs")
        if employer_id:
            query = query.where("employerId", "==", employer_id)
        
        docs = query.stream()
        jobs = []
        for doc in docs:
            data = doc.to_dict()
            data['id'] = doc.id
            jobs.append(data)
            
        jobs.sort(key=lambda x: x.get('timestamp', ''), reverse=True)
        return jobs
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
