from firebase_admin import messaging

def send_push_notification(token: str, title: str, body: str, data: dict = None):
    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data if data else {},
            token=token,
        )
        response = messaging.send(message)
        return response
    except Exception as e:
        # In a real app, you log this but don't fail the entire API request
        print(f"Push notification failed: {e}")
        return None
