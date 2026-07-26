from firebase_functions import firestore_fn
from firebase_admin import messaging

@firestore_fn.on_document_created(document="pengumuman/{docId}")
def kirim_notifikasi_pengumuman(event: firestore_fn.Event[firestore_fn.DocumentSnapshot | None]) -> None:
    if event.data is None:
        return

    data = event.data.to_dict()
    judul = data.get("judul", "Pengumuman Baru")
    konten = data.get("konten", "Ada informasi terbaru dari Posyandu.")

    message = messaging.Message(
        notification=messaging.Notification(
            title=judul,
            body=konten,
        ),
        data={
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "pengumumanId": event.params["docId"],
        },
        topic="all_users",
    )

    try:
        messaging.send(message)
    except Exception:
        pass