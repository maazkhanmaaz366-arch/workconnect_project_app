import os
import firebase_admin
from firebase_admin import credentials, firestore

key_path = os.path.join(os.path.dirname(__file__), "api", "workconnectfirebasekey.json")
if not firebase_admin._apps:
    cred = credentials.Certificate(key_path)
    firebase_admin.initialize_app(cred)

db = firestore.client()

def seed_workers():
    print("Seeding database with test workers...")
    workers = [
        {
            "fullName": "Ahmad Ali",
            "email": "ahmad@test.com",
            "role": "worker",
            "skillsList": ["Plumbing", "Phase 3 Systems", "Immediate Start"],
            "averageRating": 4.9,
            "totalReviews": 324,
            "bio": "Expert industrial electrician and plumber."
        },
        {
            "fullName": "Sarah Jenkins",
            "email": "sarah@test.com",
            "role": "worker",
            "skillsList": ["Control Circuits", "Maintenance"],
            "averageRating": 4.8,
            "totalReviews": 86,
            "bio": "Systems engineer with 10 years experience."
        },
        {
            "fullName": "Imran Khan",
            "email": "imran@test.com",
            "role": "worker",
            "skillsList": ["Carpentry", "Woodwork"],
            "averageRating": 4.5,
            "totalReviews": 12,
            "bio": "Master carpenter."
        }
    ]
    
    batch = db.batch()
    for w in workers:
        doc_ref = db.collection('users').document()
        batch.set(doc_ref, w)
        
    batch.commit()
    print("SUCCESS: 3 Mock Workers added to Firestore!")

if __name__ == "__main__":
    seed_workers()
