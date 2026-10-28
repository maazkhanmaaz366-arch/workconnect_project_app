import os
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

# Initialize Firebase
key_path = os.path.join(os.path.dirname(__file__), "api", "workconnectfirebasekey.json")
if not firebase_admin._apps:
    cred = credentials.Certificate(key_path)
    firebase_admin.initialize_app(cred)

db = firestore.client()

def test_chat():
    print("Testing Firestore Chat Connection...")
    chat_id = "global_demo_chat"
    
    # Write a test message
    test_msg = {
        "text": "Hello from the backend! Testing chat sync...",
        "senderId": "SYSTEM_TEST",
        "timestamp": firestore.SERVER_TIMESTAMP
    }
    
    try:
        doc_ref = db.collection('chats').document(chat_id).collection('messages').add(test_msg)
        print(f"SUCCESS: Wrote message to Firestore! Document ID: {doc_ref[1].id}")
        
        # Read messages
        messages = db.collection('chats').document(chat_id).collection('messages').order_by('timestamp', direction=firestore.Query.DESCENDING).limit(5).get()
        print(f"\nRecent Messages in '{chat_id}':")
        for msg in messages:
            data = msg.to_dict()
            text = data.get('text', '')
            sender = data.get('senderId', '')
            print(f" - [{sender}]: {text}")
            
    except Exception as e:
        print(f"ERROR: Failed to connect to Firestore Chat: {e}")

if __name__ == "__main__":
    test_chat()
