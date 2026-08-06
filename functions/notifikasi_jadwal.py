from firebase_functions import firestore_fn
from firebase_admin import messaging
import datetime

@firestore_fn.on_document_created(document="jadwal/{docId}")
def kirim_notifikasi_jadwal(event: firestore_fn.Event[firestore_fn.DocumentSnapshot | None]) -> None:
    if event.data is None:
        return

    data = event.data.to_dict()

    kategori = data.get("kategori", "Kegiatan")
    judul_notifikasi = f"[ Jadwal ] Kegiatan {kategori} Baru"

    lokasi = data.get("lokasi", "Posyandu")
    waktu_mulai = data.get("waktuMulai", "")
    waktu_selesai = data.get("waktuSelesai", "")
    
    tanggal_timestamp = data.get("tanggal")
    if isinstance(tanggal_timestamp, datetime.datetime):
        dt = tanggal_timestamp
        
        hari_dict = {
            0: "Senin", 1: "Selasa", 2: "Rabu", 3: "Kamis",
            4: "Jumat", 5: "Sabtu", 6: "Minggu"
        }
        bulan_dict = {
            1: "Januari", 2: "Februari", 3: "Maret", 4: "April",
            5: "Mei", 6: "Juni", 7: "Juli", 8: "Agustus",
            9: "September", 10: "Oktober", 11: "November", 12: "Desember"
        }
        
        hari_str = hari_dict.get(dt.weekday(), "")
        bulan_str = bulan_dict.get(dt.month, "")
        
        tanggal_str = f"{hari_str}, {dt.day} {bulan_str} {dt.year}"
    else:
        tanggal_str = "waktu yang ditentukan"

    waktu_str = ""
    if waktu_mulai and waktu_selesai:
        waktu_str = f" pukul {waktu_mulai} - {waktu_selesai}"
    elif waktu_mulai:
        waktu_str = f" pukul {waktu_mulai}"

    judul = data.get("judul", "kegiatan")
    konten_notifikasi = f"Kegiatan '{judul}' akan dilaksanakan di {lokasi} pada {tanggal_str}{waktu_str}."

    message = messaging.Message(
        notification=messaging.Notification(
            title=judul_notifikasi,
            body=konten_notifikasi,
        ),
        data={
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "jadwalId": event.params["docId"],
            "tipe": "jadwal",
        },
        topic="all_users",
    )

    try:
        messaging.send(message)
    except Exception:
        pass
