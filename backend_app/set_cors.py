import firebase_admin
from firebase_admin import credentials, storage
import os

key_path = os.path.join(os.path.dirname(__file__), "api", "workconnectfirebasekey.json")
cred = credentials.Certificate(key_path)
firebase_admin.initialize_app(cred, {
    'storageBucket': 'workconnected-8cf3c.firebasestorage.app'
})

bucket = storage.bucket()
bucket.cors = [
    {
        "origin": ["*"],
        "responseHeader": ["*"],
        "method": ["GET", "PUT", "POST", "DELETE", "HEAD", "OPTIONS"],
        "maxAgeSeconds": 3600
    }
]
bucket.patch()
print("CORS configured successfully for workconnected-8cf3c.firebasestorage.app")
