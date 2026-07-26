import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class LaporanBalitaScreen extends StatefulWidget {
  const LaporanBalitaScreen({super.key});

  @override
  State<LaporanBalitaScreen> createState() => _LaporanBalitaScreenState();
}

class _LaporanBalitaScreenState extends State<LaporanBalitaScreen> {
  bool _isLoading = false;

  Future<void> _buatDanUnduhLaporan() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final balitaSnapshot = await FirebaseFirestore.instance
          .collection('balita')
          .where('isHidden', isEqualTo: false)
          .get();

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Laporan Data Balita Posyandu',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.TableHelper.fromTextArray(
                  context: context,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  data: <List<String>>[
                    <String>['Nama Balita', 'Jenis Kelamin', 'Nama Orang Tua'],
                    ...balitaSnapshot.docs.map((doc) {
                      final data = doc.data();
                      return [
                        data['nama']?.toString() ?? '-',
                        data['jenisKelamin']?.toString() ?? '-',
                        data['namaOrangTua']?.toString() ?? '-',
                      ];
                    }),
                  ],
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Laporan_Balita_Posyandu.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat laporan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unduh Laporan'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                onPressed: _buatDanUnduhLaporan,
                icon: const Icon(Icons.download_rounded),
                label: const Text('Unduh Laporan PDF'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ),
    );
  }
}
