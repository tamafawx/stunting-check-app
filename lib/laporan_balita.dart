import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const PdfColor _kAccent = PdfColor.fromInt(0xFF2E7D32);
const PdfColor _kAccentDark = PdfColor.fromInt(0xFF1B4F1E);

const PdfColor _kAmanBg = PdfColor.fromInt(0xFFE8F5E9);
const PdfColor _kAmanFg = PdfColor.fromInt(0xFF2E7D32);
const PdfColor _kWaspadaBg = PdfColor.fromInt(0xFFFFF3E0);
const PdfColor _kWaspadaFg = PdfColor.fromInt(0xFFEF6C00);
const PdfColor _kStuntingBg = PdfColor.fromInt(0xFFFFEBEE);
const PdfColor _kStuntingFg = PdfColor.fromInt(0xFFC62828);

String formatTanggalLahirBalita(dynamic dateData) {
  if (dateData == null) return "-";
  DateTime? date;
  if (dateData is Timestamp) {
    date = dateData.toDate();
  } else if (dateData is DateTime) {
    date = dateData;
  } else if (dateData is String) {
    date = DateTime.tryParse(dateData);
  }
  if (date == null) return "-";
  const monthNames = [
    "Januari",
    "Februari",
    "Maret",
    "April",
    "Mei",
    "Juni",
    "Juli",
    "Agustus",
    "September",
    "Oktober",
    "November",
    "Desember",
  ];
  return "${date.day.toString().padLeft(2, '0')} ${monthNames[date.month - 1]} ${date.year}";
}

({String label, PdfColor bg, PdfColor fg}) _statusBadgeInfo(String? raw) {
  final s = (raw ?? "").toLowerCase();
  if (s.contains("tinggi") || s.contains("sangat pendek")) {
    return (label: "Stunting", bg: _kStuntingBg, fg: _kStuntingFg);
  } else if (s.contains("sedang") || s.contains("pendek")) {
    return (label: "Risiko Sedang", bg: _kWaspadaBg, fg: _kWaspadaFg);
  } else if (s.isEmpty) {
    return (
      label: "Belum Diketahui",
      bg: PdfColors.grey200,
      fg: PdfColors.grey700,
    );
  }
  return (label: "Aman", bg: _kAmanBg, fg: _kAmanFg);
}

Future<Uint8List?> _unduhFoto(String? fotoUrl) async {
  if (fotoUrl == null || fotoUrl.isEmpty) return null;
  try {
    final response = await http
        .get(Uri.parse(fotoUrl))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
  } catch (_) {}
  return null;
}

Future<List<Map<String, dynamic>>> _ambilRiwayatPemeriksaan(
  String balitaId,
) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('pemeriksaan')
        .where('balitaId', isEqualTo: balitaId)
        .get();
    final docs = snapshot.docs.toList();
    docs.sort((a, b) {
      final tA =
          (a.data()['tanggal'] as Timestamp?) ??
          Timestamp.fromMillisecondsSinceEpoch(0);
      final tB =
          (b.data()['tanggal'] as Timestamp?) ??
          Timestamp.fromMillisecondsSinceEpoch(0);
      return tA.compareTo(tB);
    });
    return docs.map((d) => d.data()).toList();
  } catch (_) {
    return [];
  }
}

Future<void> generateLaporanBalita({
  required String balitaId,
  required String idBalita,
  required String nama,
  required String jenisKelamin,
  required String usia,
  required dynamic tanggalLahirData,
  String? fotoUrl,
}) async {
  final String tanggalLahir = formatTanggalLahirBalita(tanggalLahirData);
  final String tanggalCetak = formatTanggalLahirBalita(DateTime.now());
  final String inisial = nama.trim().isNotEmpty
      ? nama.trim().substring(0, 1).toUpperCase()
      : "?";

  final results = await Future.wait([
    _unduhFoto(fotoUrl),
    _ambilRiwayatPemeriksaan(balitaId),
  ]);
  final Uint8List? fotoBytes = results[0] as Uint8List?;
  final List<Map<String, dynamic>> riwayat =
      results[1] as List<Map<String, dynamic>>;

  final pdf = pw.Document();

  pw.Widget buildFotoSquircle({double size = 85}) {
    final double radius = size * 0.28;
    if (fotoBytes != null) {
      return pw.ClipRRect(
        horizontalRadius: radius,
        verticalRadius: radius,
        child: pw.Image(
          pw.MemoryImage(fotoBytes),
          width: size,
          height: size,
          fit: pw.BoxFit.cover,
        ),
      );
    }
    return pw.Container(
      width: size,
      height: size,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        color: _kAccent,
        borderRadius: pw.BorderRadius.circular(radius),
      ),
      child: pw.Text(
        inisial,
        style: pw.TextStyle(
          fontSize: size * 0.4,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  pw.Widget buildInfoRow({
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: isLast
          ? null
          : const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
              ),
            ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 3,
            height: 16,
            decoration: pw.BoxDecoration(
              color: _kAccent,
              borderRadius: pw.BorderRadius.circular(2),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.SizedBox(
            width: 90,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget buildSplitInfoRow({
    required String label1,
    required String value1,
    required String label2,
    required String value2,
    bool isLast = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: isLast
          ? null
          : const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
              ),
            ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            flex: 6,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: 3,
                  height: 16,
                  decoration: pw.BoxDecoration(
                    color: _kAccent,
                    borderRadius: pw.BorderRadius.circular(2),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.SizedBox(
                  width: 90,
                  child: pw.Text(
                    label1,
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    value1,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            flex: 4,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: 3,
                  height: 16,
                  decoration: pw.BoxDecoration(
                    color: _kAccent,
                    borderRadius: pw.BorderRadius.circular(2),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.SizedBox(
                  width: 30,
                  child: pw.Text(
                    label2,
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    value2,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget buildStatusBadge(String? statusRaw) {
    final info = _statusBadgeInfo(statusRaw);
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        color: info.bg,
        borderRadius: pw.BorderRadius.circular(20),
      ),
      child: pw.Text(
        info.label,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: info.fg,
        ),
      ),
    );
  }

  pw.Widget buildTableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  pw.Widget buildTableCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 9),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.grey900,
        ),
      ),
    );
  }

  pw.Widget buildRiwayatTable(List<Map<String, dynamic>> data) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.75),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.7),
        1: pw.FlexColumnWidth(1.8),
        2: pw.FlexColumnWidth(1.0),
        3: pw.FlexColumnWidth(1.0),
        4: pw.FlexColumnWidth(1.0),
        5: pw.FlexColumnWidth(1.1),
        6: pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _kAccent),
          children: [
            buildTableHeaderCell("Ke-"),
            buildTableHeaderCell("Tanggal"),
            buildTableHeaderCell("BB (kg)"),
            buildTableHeaderCell("TB (cm)"),
            buildTableHeaderCell("LK (cm)"),
            buildTableHeaderCell("LILA (cm)"),
            buildTableHeaderCell("Status"),
          ],
        ),
        ...data.asMap().entries.map((entry) {
          final int index = entry.key;
          final Map<String, dynamic> item = entry.value;
          final String tanggal = formatTanggalLahirBalita(item['tanggal']);
          final num berat = (item['beratBadan'] is num)
              ? item['beratBadan']
              : 0;
          final num tinggi = (item['tinggiBadan'] is num)
              ? item['tinggiBadan']
              : 0;
          final num lingkarKepala = (item['lingkarKepala'] is num)
              ? item['lingkarKepala']
              : 0;
          final num lingkarLengan = (item['lingkarLengan'] is num)
              ? item['lingkarLengan']
              : 0;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: index % 2 == 0 ? PdfColors.white : PdfColors.grey100,
            ),
            children: [
              buildTableCell("${index + 1}", bold: true),
              buildTableCell(tanggal, bold: true),
              buildTableCell(berat.toStringAsFixed(1)),
              buildTableCell(tinggi.toStringAsFixed(1)),
              buildTableCell(lingkarKepala.toStringAsFixed(1)),
              buildTableCell(lingkarLengan.toStringAsFixed(1)),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                child: buildStatusBadge(item['statusStunting'] as String?),
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget buildLegendDot(PdfColor color, String label) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 10,
          height: 10,
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: 5),
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ],
    );
  }

  pw.Widget buildGrafikPertumbuhan(List<Map<String, dynamic>> data) {
    if (data.length < 2) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(12),
          border: pw.Border.all(color: PdfColors.grey300, width: 1),
        ),
        child: pw.Text(
          "Data belum memadai untuk membentuk grafik pertumbuhan (minimal 2 data pemeriksaan).",
          style: pw.TextStyle(fontSize: 10.5, color: PdfColors.grey600),
        ),
      );
    }

    final List<pw.PointChartValue> tinggiPoints = [];
    final List<pw.PointChartValue> beratPoints = [];
    for (int i = 0; i < data.length; i++) {
      final num berat = (data[i]['beratBadan'] is num)
          ? data[i]['beratBadan']
          : 0;
      final num tinggi = (data[i]['tinggiBadan'] is num)
          ? data[i]['tinggiBadan']
          : 0;
      tinggiPoints.add(pw.PointChartValue(i.toDouble(), tinggi.toDouble()));
      beratPoints.add(pw.PointChartValue(i.toDouble(), berat.toDouble()));
    }

    return pw.Container(
      width: double.infinity,
      height: 240,
      padding: const pw.EdgeInsets.fromLTRB(16, 16, 22, 10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
      ),
      child: pw.Chart(
        grid: pw.CartesianGrid(
          xAxis: pw.FixedAxis.fromStrings(
            List.generate(data.length, (i) => "${i + 1}"),
            marginStart: 20,
            marginEnd: 20,
            ticks: true,
            color: PdfColors.grey300,
            textStyle: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          yAxis: pw.FixedAxis<int>(
            const [0, 25, 50, 75, 100, 125, 150],
            divisions: true,
            color: PdfColors.grey300,
            textStyle: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        datasets: [
          pw.LineDataSet(
            legend: "Tinggi Badan (cm)",
            data: tinggiPoints,
            isCurved: true,
            drawPoints: true,
            color: _kAccentDark,
            lineWidth: 2.5,
            pointSize: 4,
            drawSurface: true,
            surfaceOpacity: 0.1,
            surfaceColor: _kAccentDark,
          ),
          pw.LineDataSet(
            legend: "Berat Badan (kg)",
            data: beratPoints,
            isCurved: true,
            drawPoints: true,
            color: _kAccent,
            lineWidth: 2.5,
            pointSize: 4,
            drawSurface: true,
            surfaceOpacity: 0.2,
            surfaceColor: _kAccent,
          ),
        ],
        bottom: pw.Padding(
          padding: const pw.EdgeInsets.only(top: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              buildLegendDot(_kAccentDark, "Tinggi Badan (cm)"),
              pw.SizedBox(width: 16),
              buildLegendDot(_kAccent, "Berat Badan (kg)"),
            ],
          ),
        ),
      ),
    );
  }

  pw.Widget buildInformasiTerakhir(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(12),
          border: pw.Border.all(color: PdfColors.grey300, width: 1),
        ),
        child: pw.Text(
          "Belum ada data pemeriksaan terbaru.",
          style: pw.TextStyle(fontSize: 10.5, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
      );
    }

    final latest = data.last;
    final statusRaw = latest['statusStunting'] as String?;
    final info = _statusBadgeInfo(statusRaw);

    final bb = (latest['beratBadan'] is num)
        ? (latest['beratBadan'] as num).toStringAsFixed(1)
        : '-';
    final tb = (latest['tinggiBadan'] is num)
        ? (latest['tinggiBadan'] as num).toStringAsFixed(1)
        : '-';
    final lk = (latest['lingkarKepala'] is num)
        ? (latest['lingkarKepala'] as num).toStringAsFixed(1)
        : '-';
    final lila = (latest['lingkarLengan'] is num)
        ? (latest['lingkarLengan'] as num).toStringAsFixed(1)
        : '-';
    final tgl = formatTanggalLahirBalita(latest['tanggal']);

    final pesanRaw =
        latest['pesan'] ?? latest['catatan'] ?? latest['saran'] ?? '';
    final hasPesan = pesanRaw.toString().trim().isNotEmpty;
    final pesanTampil = hasPesan
        ? pesanRaw.toString().trim()
        : "Belum ada saran dan rekomendasi dari kader/bidan!";

    pw.Widget buildMetric(String label, String value, String unit) {
      return pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 2),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  value,
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey900,
                  ),
                ),
                pw.SizedBox(width: 2),
                pw.Text(
                  unit,
                  style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 6,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: info.bg,
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: info.fg, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  "STATUS GIZI: ${info.label.toUpperCase()}",
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: info.fg,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  "Pemeriksaan: $tgl",
                  style: pw.TextStyle(fontSize: 8, color: info.fg),
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    children: [
                      buildMetric("BB", bb, "kg"),
                      pw.Container(
                        width: 1,
                        height: 16,
                        color: PdfColors.grey300,
                      ),
                      buildMetric("TB", tb, "cm"),
                      pw.Container(
                        width: 1,
                        height: 16,
                        color: PdfColors.grey300,
                      ),
                      buildMetric("LK", lk, "cm"),
                      pw.Container(
                        width: 1,
                        height: 16,
                        color: PdfColors.grey300,
                      ),
                      buildMetric("LILA", lila, "cm"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          flex: 4,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: PdfColors.grey300, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "CATATAN / PESAN",
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  pesanTampil,
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    color: hasPesan ? PdfColors.grey900 : PdfColors.grey600,
                    fontStyle: hasPesan
                        ? pw.FontStyle.normal
                        : pw.FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget buildHeaderBanner() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 28),
      decoration: const pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [_kAccent, _kAccentDark],
          begin: pw.Alignment.centerLeft,
          end: pw.Alignment.centerRight,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            "LAPORAN DATA BALITA",
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              letterSpacing: 0.5,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            "Posyandu Stunting \u2022 Program Pemantauan Tumbuh Kembang",
            style: pw.TextStyle(fontSize: 9.5, color: PdfColors.white),
          ),
        ],
      ),
    );
  }

  pw.Widget buildHeaderLanjutan(int pageNumber) {
    return pw.Container(
      width: double.infinity,
      color: _kAccent,
      padding: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 14),
      child: pw.Text(
        "LAPORAN DATA BALITA \u2014 $nama (lanjutan)",
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  pw.Widget buildFooter(pw.Context context) {
    return pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(36, 10, 36, 20),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "Dicetak: $tanggalCetak   |   Aplikasi Posyandu",
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey500,
                ),
              ),
              pw.Text(
                "Halaman ${context.pageNumber} dari ${context.pagesCount}",
                style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      header: (context) => context.pageNumber == 1
          ? buildHeaderBanner()
          : buildHeaderLanjutan(context.pageNumber),
      footer: (context) => buildFooter(context),
      build: (context) => [
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(36, 28, 36, 10),
          child: pw.Text(
            "DETAIL DATA",
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey500,
              letterSpacing: 1,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 36),
          child: pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(14),
              border: pw.Border.all(color: PdfColors.grey300, width: 1),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                buildFotoSquircle(size: 85),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  child: pw.Column(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      buildInfoRow(label: "ID Balita", value: idBalita),
                      buildInfoRow(label: "Nama Lengkap", value: nama),
                      buildInfoRow(label: "Jenis Kelamin", value: jenisKelamin),
                      buildSplitInfoRow(
                        label1: "Tanggal Lahir",
                        value1: tanggalLahir,
                        label2: "Umur",
                        value2: usia,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(36, 24, 36, 10),
          child: pw.Text(
            "INFORMASI PEMERIKSAAN TERAKHIR",
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey500,
              letterSpacing: 1,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 36),
          child: buildInformasiTerakhir(riwayat),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(36, 24, 36, 10),
          child: pw.Text(
            "GRAFIK PERTUMBUHAN",
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey500,
              letterSpacing: 1,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 36),
          child: buildGrafikPertumbuhan(riwayat),
        ),
        pw.SizedBox(height: 20),
      ],
    ),
  );

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      header: (context) => buildHeaderLanjutan(context.pageNumber),
      footer: (context) => buildFooter(context),
      build: (context) => [
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(36, 28, 36, 10),
          child: pw.Text(
            "RIWAYAT PEMERIKSAAN",
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey500,
              letterSpacing: 1,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 36),
          child: riwayat.isEmpty
              ? pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(12),
                    border: pw.Border.all(color: PdfColors.grey300, width: 1),
                  ),
                  child: pw.Text(
                    "Belum ada riwayat pemeriksaan untuk balita ini.",
                    style: pw.TextStyle(
                      fontSize: 10.5,
                      color: PdfColors.grey600,
                    ),
                  ),
                )
              : buildRiwayatTable(riwayat),
        ),
        pw.SizedBox(height: 30),
      ],
    ),
  );

  await Printing.layoutPdf(
    onLayout: (format) async => pdf.save(),
    name: "Laporan_${nama.replaceAll(' ', '_')}.pdf",
  );
}
