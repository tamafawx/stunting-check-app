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

({String label, PdfColor bg, PdfColor fg}) _statusBadgeInfo(String? raw) {
  final s = (raw ?? "").toLowerCase();
  if (s.contains("tinggi") || s.contains("sangat pendek")) {
    return (label: "Stunting", bg: _kStuntingBg, fg: _kStuntingFg);
  } else if (s.contains("sedang") || s.contains("pendek")) {
    return (label: "Risiko Sedang", bg: _kWaspadaBg, fg: _kWaspadaFg);
  } else if (s.isEmpty || s.contains("memproses") || s.contains("belum")) {
    return (
      label: "Belum Diketahui",
      bg: PdfColors.grey200,
      fg: PdfColors.grey700,
    );
  }
  return (label: "Aman", bg: _kAmanBg, fg: _kAmanFg);
}

Future<void> generateLaporanPemeriksaanHarian({
  required DateTime tanggalTerpilih,
  required List<Map<String, dynamic>> dataPemeriksaan,
}) async {
  final pdf = pw.Document();

  final String tanggalCetak =
      "${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}";

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
  final String tanggalLaporan =
      "${tanggalTerpilih.day.toString().padLeft(2, '0')} ${monthNames[tanggalTerpilih.month - 1]} ${tanggalTerpilih.year}";

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
            "REKAPITULASI PEMERIKSAAN POSYANDU",
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              letterSpacing: 0.5,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            "Tanggal Pemeriksaan: $tanggalLaporan",
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            "Total Data: ${dataPemeriksaan.length} Balita Diukur",
            style: pw.TextStyle(fontSize: 10, color: PdfColors.white),
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
        "REKAP PEMERIKSAAN \u2014 $tanggalLaporan (lanjutan)",
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
                "Dicetak: $tanggalCetak \u2022 Aplikasi Posyandu",
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

  pw.Widget buildStatusBadge(String? statusRaw) {
    final info = _statusBadgeInfo(statusRaw);
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: info.bg,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Text(
        info.label,
        style: pw.TextStyle(
          fontSize: 8,
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

  pw.Widget buildTableCell(
    String text, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.center,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.grey900,
        ),
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
          padding: const pw.EdgeInsets.fromLTRB(36, 24, 36, 10),
          child: pw.Text(
            "DATA PENGUKURAN HARIAN",
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
          child: dataPemeriksaan.isEmpty
              ? pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(12),
                    border: pw.Border.all(color: PdfColors.grey300, width: 1),
                  ),
                  child: pw.Text(
                    "Tidak ada data pemeriksaan pada tanggal ini.",
                    style: pw.TextStyle(
                      fontSize: 10.5,
                      color: PdfColors.grey600,
                    ),
                  ),
                )
              : pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey300,
                    width: 0.75,
                  ),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(0.6), // No
                    1: pw.FlexColumnWidth(2.5), // Nama
                    2: pw.FlexColumnWidth(1.0), // BB
                    3: pw.FlexColumnWidth(1.0), // TB
                    4: pw.FlexColumnWidth(1.0), // LK
                    5: pw.FlexColumnWidth(1.0), // LILA
                    6: pw.FlexColumnWidth(1.6), // Status
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: _kAccent),
                      children: [
                        buildTableHeaderCell("No"),
                        buildTableHeaderCell("Nama Anak"),
                        buildTableHeaderCell("BB (kg)"),
                        buildTableHeaderCell("TB (cm)"),
                        buildTableHeaderCell("LK (cm)"),
                        buildTableHeaderCell("LILA (cm)"),
                        buildTableHeaderCell("Status Gizi"),
                      ],
                    ),
                    ...dataPemeriksaan.asMap().entries.map((entry) {
                      final int index = entry.key;
                      final Map<String, dynamic> item = entry.value;

                      final String nama = item['namaBalita'] ?? '-';
                      final num bb = (item['beratBadan'] is num)
                          ? item['beratBadan']
                          : 0;
                      final num tb = (item['tinggiBadan'] is num)
                          ? item['tinggiBadan']
                          : 0;
                      final num lk = (item['lingkarKepala'] is num)
                          ? item['lingkarKepala']
                          : 0;
                      final num lila = (item['lingkarLengan'] is num)
                          ? item['lingkarLengan']
                          : 0;

                      return pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: index % 2 == 0
                              ? PdfColors.white
                              : PdfColors.grey100,
                        ),
                        children: [
                          buildTableCell("${index + 1}", bold: true),
                          buildTableCell(
                            nama,
                            align: pw.TextAlign.left,
                            bold: true,
                          ),
                          buildTableCell(bb > 0 ? bb.toStringAsFixed(1) : '-'),
                          buildTableCell(tb > 0 ? tb.toStringAsFixed(1) : '-'),
                          buildTableCell(lk > 0 ? lk.toStringAsFixed(1) : '-'),
                          buildTableCell(
                            lila > 0 ? lila.toStringAsFixed(1) : '-',
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 6,
                            ),
                            child: pw.Center(
                              child: buildStatusBadge(
                                item['statusStunting'] as String?,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
        ),
        pw.SizedBox(height: 30),
      ],
    ),
  );

  await Printing.layoutPdf(
    onLayout: (format) async => pdf.save(),
    name:
        "Laporan_Pemeriksaan_${tanggalTerpilih.day}_${tanggalTerpilih.month}_${tanggalTerpilih.year}.pdf",
  );
}
