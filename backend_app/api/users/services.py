from fastapi import HTTPException
from firebase_admin import firestore

def create_or_update_worker(uid: str, profile_data: dict):
    try:
        db = firestore.client()
        worker_ref = db.collection("workers").document(uid)
        
        # Add basic defaults if this is a new profile
        worker_doc = worker_ref.get()
        if not worker_doc.exists:
            profile_data["averageRating"] = 0.0
            profile_data["totalReviews"] = 0
            profile_data["isVerified"] = False
        
        worker_ref.set(profile_data, merge=True)
        return {"uid": uid, "message": "Worker profile updated successfully."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def get_worker(uid: str):
    try:
        db = firestore.client()
        worker_doc = db.collection("workers").document(uid).get()
        if not worker_doc.exists:
            raise HTTPException(status_code=404, detail="Worker not found.")
        return worker_doc.to_dict()
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def update_verification_status(uid: str, is_verified: bool):
    try:
        db = firestore.client()
        worker_ref = db.collection("workers").document(uid)
        
        # Make sure worker exists
        if not worker_ref.get().exists:
            raise HTTPException(status_code=404, detail="Worker not found.")
            
        worker_ref.update({"isVerified": is_verified})
        return {"uid": uid, "message": f"Worker verification set to {is_verified}."}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def delete_user_entirely(uid: str):
    try:
        from firebase_admin import auth
        db = firestore.client()
        # Delete from Firebase Auth
        try:
            auth.delete_user(uid)
        except Exception as auth_err:
            print(f"Auth delete error (maybe already deleted): {auth_err}")
            
        # Delete from Firestore
        db.collection("users").document(uid).delete()
        
        return {"uid": uid, "message": "User permanently removed from Auth and Firestore."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
