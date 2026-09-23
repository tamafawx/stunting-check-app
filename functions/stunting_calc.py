import os
import pandas as pd
from firebase_functions import firestore_fn

def hitung_status_tinggi_badan(tinggi_badan: float, umur_bulan: int, jenis_kelamin: str, posisi_ukur: str) -> str:
    if umur_bulan > 60: return "Umur di luar jangkauan (>60 bulan)"
    gender_str = "boys" if jenis_kelamin.lower() == "laki-laki" else "girls"
    
    if umur_bulan < 24:
        age_group = "0-to-2-years"
    elif umur_bulan == 24:
        age_group = "2-to-5-years" if posisi_ukur.lower() == "berdiri" else "0-to-2-years"
    else:
        age_group = "2-to-5-years"
    
    csv_filename = f"lhfa_{gender_str}_{age_group}_zscores.csv"
    csv_path = os.path.join(os.path.dirname(__file__), "csv", csv_filename)
    try:
        df = pd.read_csv(csv_path)
        df.columns = df.columns.str.strip()
        row = df[df['Month'] == umur_bulan]
        if row.empty: return "Data umur tidak ditemukan"
        
        sd3neg, sd2neg, sd3 = row.iloc[0]['SD3neg'], row.iloc[0]['SD2neg'], row.iloc[0]['SD3']
        if tinggi_badan < sd3neg: return "Sangat Pendek (Severely Stunted)"
        elif sd3neg <= tinggi_badan < sd2neg: return "Pendek (Stunted)"
        elif sd2neg <= tinggi_badan <= sd3: return "Normal"
        else: return "Tinggi"
    except Exception as e: return f"Error: {e}"

def hitung_status_berat_badan(berat_badan: float, umur_bulan: int, jenis_kelamin: str) -> str:
    if umur_bulan > 60: return "Umur di luar jangkauan (>60 bulan)"
    gender_str = "boys" if jenis_kelamin.lower() == "laki-laki" else "girls"
    csv_filename = f"wfa_{gender_str}_0-to-5-years_zscores.csv"
    csv_path = os.path.join(os.path.dirname(__file__), "csv", csv_filename)
    try:
        df = pd.read_csv(csv_path)
        df.columns = df.columns.str.strip()
        row = df[df['Month'] == umur_bulan]
        if row.empty: return "Data umur tidak ditemukan"
        
        sd3neg, sd2neg, sd1 = row.iloc[0]['SD3neg'], row.iloc[0]['SD2neg'], row.iloc[0]['SD1']
        if berat_badan < sd3neg: return "Sangat Kurang (Severely Underweight)"
        elif sd3neg <= berat_badan < sd2neg: return "Kurang (Underweight)"
        elif sd2neg <= berat_badan <= sd1: return "Normal"
        else: return "Risiko Lebih"
    except Exception as e: return f"Error: {e}"

def hitung_status_lingkar_kepala(lingkar_kepala: float, umur_bulan: int, jenis_kelamin: str) -> str:
    if umur_bulan > 60: return "Umur di luar jangkauan (>60 bulan)"
    gender_str = "boys" if jenis_kelamin.lower() == "laki-laki" else "girls"
    csv_filename = f"hcfa-{gender_str}-0-5-zscores.csv"
    csv_path = os.path.join(os.path.dirname(__file__), "csv", csv_filename)
    try:
        df = pd.read_csv(csv_path)
        df.columns = df.columns.str.strip()
        row = df[df['Month'] == umur_bulan]
        if row.empty: return "Data umur tidak ditemukan"
        
        sd2neg, sd2 = row.iloc[0]['SD2neg'], row.iloc[0]['SD2']
        if lingkar_kepala < sd2neg: return "Mikrosefali (< -2 SD)"
        elif sd2neg <= lingkar_kepala <= sd2: return "Normal"
        else: return "Makrosefali (> 2 SD)"
    except Exception as e: return f"Error: {e}"

def hitung_status_lingkar_lengan(lingkar_lengan: float, umur_bulan: int, jenis_kelamin: str) -> str:
    if umur_bulan < 3 or umur_bulan > 60: return "Pengukuran LiLA hanya untuk usia 3-60 bulan"
    if lingkar_lengan <= 0.0: return "Tidak diukur"
    gender_str = "boys" if jenis_kelamin.lower() == "laki-laki" else "girls"
    csv_filename = f"acfa-{gender_str}-3-5-zscores.csv"
    csv_path = os.path.join(os.path.dirname(__file__), "csv", csv_filename)
    try:
        df = pd.read_csv(csv_path)
        df.columns = df.columns.str.strip()
        row = df[df['Month'] == umur_bulan]
        if row.empty: return "Data umur tidak ditemukan"
        
        sd3neg, sd2neg = row.iloc[0]['SD3neg'], row.iloc[0]['SD2neg']
        if lingkar_lengan < sd3neg: return "Gizi Buruk (Severely Wasted)"
        elif sd3neg <= lingkar_lengan < sd2neg: return "Gizi Kurang (Wasted)"
        else: return "Normal"
    except Exception as e: return f"Error: {e}"

def hitung_status_keseluruhan(status_tb: str, status_bb: str, status_lk: str, status_lila: str) -> str:
    statuses = [status_tb, status_bb, status_lk, status_lila]
    
    fatal_keywords = ["Sangat Pendek", "Sangat Kurang", "Gizi Buruk"]
    rendah_keywords = ["Pendek", "Kurang", "Gizi Kurang", "Mikrosefali", "Makrosefali", "Risiko Lebih", "Tinggi"]
    
    for status in statuses:
        if any(keyword in status for keyword in fatal_keywords):
            return "Risiko Tinggi"
            
    for status in statuses:
        if any(keyword in status for keyword in rendah_keywords):
            return "Risiko Rendah"
            
    return "Aman"

@firestore_fn.on_document_created(document="pemeriksaan/{docId}")
def proses_kalkulasi_stunting(event: firestore_fn.Event[firestore_fn.DocumentSnapshot | None]) -> None:
    if event.data is None:
        return

    data = event.data.to_dict()
    umur_bulan = int(data.get("umurBulan", 0))
    jenis_kelamin = data.get("jenisKelamin", "Laki-laki")
    
    tinggi_badan = float(data.get("tinggiBadan", 0.0))
    berat_badan = float(data.get("beratBadan", 0.0))
    lingkar_kepala = float(data.get("lingkarKepala", 0.0))
    lingkar_lengan = float(data.get("lingkarLengan", 0.0))
    posisi_ukur = data.get("posisiUkurTB", "Berbaring")

    status_tb = hitung_status_tinggi_badan(tinggi_badan, umur_bulan, jenis_kelamin, posisi_ukur)
    status_bb = hitung_status_berat_badan(berat_badan, umur_bulan, jenis_kelamin)
    status_lk = hitung_status_lingkar_kepala(lingkar_kepala, umur_bulan, jenis_kelamin)
    status_lila = hitung_status_lingkar_lengan(lingkar_lengan, umur_bulan, jenis_kelamin)
    
    status_balita = hitung_status_keseluruhan(status_tb, status_bb, status_lk, status_lila)
    
    event.data.reference.update({
        "statusTinggiBadan": status_tb,
        "statusBeratBadan": status_bb,
        "statusLingkarKepala": status_lk,
        "statusLingkarLengan": status_lila,
        "statusBalita": status_balita,
        "test": True,
    })