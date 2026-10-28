from fastapi import HTTPException
from firebase_admin import firestore
import uuid

def submit_review(review_data: dict):
    try:
        if not (1 <= review_data["rating"] <= 5):
            raise HTTPException(status_code=400, detail="Rating must be between 1 and 5.")

        db = firestore.client()
        review_id = str(uuid.uuid4())
        worker_id = review_data["workerId"]

        # We run this in a transaction because we are reading current averages and calculating new ones
        @firestore.transactional
        def update_in_transaction(transaction, worker_ref):
            worker_snapshot = worker_ref.get(transaction=transaction)
            if not worker_snapshot.exists:
                raise Exception("Worker not found.")

            worker = worker_snapshot.to_dict()
            current_total = worker.get("totalReviews", 0)
            current_average = worker.get("averageRating", 0.0)

            # Calculate the new rolling average
            new_total = current_total + 1
            new_average = ((current_average * current_total) + review_data["rating"]) / new_total

            # Logic for Auto-Verification
            is_verified = worker.get("isVerified", False)
            if new_average > 4.0 and new_total >= 5:
                is_verified = True

            # 1. Update the worker's aggregated rating
            transaction.update(worker_ref, {
                "averageRating": new_average,
                "totalReviews": new_total,
                "isVerified": is_verified
            })

            # 2. Add the actual review document
            review_ref = db.collection("reviews").document(review_id)
            transaction.set(review_ref, review_data)

        worker_ref = db.collection("workers").document(worker_id)
        transaction = db.transaction()
        update_in_transaction(transaction, worker_ref)

        return {"reviewId": review_id, "message": "Review submitted successfully."}

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
