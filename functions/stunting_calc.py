from firebase_functions import firestore_fn

def hitung_status_stunting(tinggi_badan: float, umur_bulan: int, jenis_kelamin: str) -> str:
    if tinggi_badan < 60.0:
        return "Risiko Tinggi"
    elif 60.0 <= tinggi_badan < 70.0:
        return "Risiko Rendah"
    else:
        return "Aman"

@firestore_fn.on_document_created(document="pemeriksaan/{docId}")
def proses_kalkulasi_stunting(event: firestore_fn.Event[firestore_fn.DocumentSnapshot | None]) -> None:
    if event.data is None:
        return

    data = event.data.to_dict()
    tinggi_badan = float(data.get("tinggiBadan", 0.0))
    umur_bulan = int(data.get("umurBulan", 0))
    jenis_kelamin = data.get("jenisKelamin", "Laki-laki")

    status = hitung_status_stunting(tinggi_badan, umur_bulan, jenis_kelamin)
    
    event.data.reference.update({"statusStunting": status})