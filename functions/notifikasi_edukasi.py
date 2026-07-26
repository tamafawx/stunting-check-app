from firebase_functions import firestore_fn
from firebase_admin import messaging

@firestore_fn.on_document_created(document="edukasi/{docId}")
def kirim_notifikasi_edukasi(event: firestore_fn.Event[firestore_fn.DocumentSnapshot | None]) -> None:
    if event.data is None:
        return

    data = event.data.to_dict()
    
    judul_asli = data.get("judul", "Edukasi Baru")
    judul_notifikasi = f"[ EDUKASI ] {judul_asli}"
    
    konten_asli = data.get("konten", "Ada materi edukasi terbaru.")
    baris_konten = konten_asli.splitlines()
    konten_notifikasi = "\n".join(baris_konten[:2])

    message = messaging.Message(
        notification=messaging.Notification(
            title=judul_notifikasi,
            body=konten_notifikasi,
        ),
        data={
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "edukasiId": event.params["docId"],
        },
        topic="all_users",
    )

    try:
        messaging.send(message)
    except Exception:
        pass