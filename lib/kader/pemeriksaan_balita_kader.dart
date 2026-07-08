import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cari_balita_pemeriksaan_kader.dart';

class InputPengukuranScreen extends StatefulWidget {
  const InputPengukuranScreen({super.key});

  @override
  State<InputPengukuranScreen> createState() => _InputPengukuranScreenState();
}

class _InputPengukuranScreenState extends State<InputPengukuranScreen> {
  final _formKey = GlobalKey<FormState>();

  // Variabel untuk menyimpan data balita yang dipilih
  Map<String, dynamic>? _selectedBalita;

  final TextEditingController _bbController = TextEditingController();
  final TextEditingController _tbController = TextEditingController();
  final TextEditingController _lkController = TextEditingController();
  final TextEditingController _lilaController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _bbController.dispose();
    _tbController.dispose();
    _lkController.dispose();
    _lilaController.dispose();
    super.dispose();
  }

  String _hitungStatusStunting(
    String jk,
    DateTime tglLahir,
    DateTime tglUkur,
    double tb,
  ) {
    int usiaBulan = tglUkur.difference(tglLahir).inDays ~/ 30;
    double batasNormal = jk == 'Laki-laki'
        ? (usiaBulan * 0.8) + 50
        : (usiaBulan * 0.75) + 49;
    double batasStunting = batasNormal - 5;
    double batasSevere = batasNormal - 8;

    if (tb < batasSevere) {
      return "Risiko Tinggi";
    } else if (tb < batasStunting) {
      return "Risiko Sedang";
    } else {
      return "Normal";
    }
  }

  Future<void> _pilihBalita() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PilihBalitaPemeriksaanScreen(),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _selectedBalita = result;
      });
    }
  }

  Future<void> _simpanPengukuran() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedBalita == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Harap pilih Balita terlebih dahulu',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.amber,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        double bb = double.parse(_bbController.text.replaceAll(',', '.'));
        double tb = double.parse(_tbController.text.replaceAll(',', '.'));
        double lk = double.parse(_lkController.text.replaceAll(',', '.'));
        double lila = double.parse(_lilaController.text.replaceAll(',', '.'));

        DateTime tglLahir = DateTime.now();
        if (_selectedBalita!['tanggalLahir'] != null) {
          tglLahir = (_selectedBalita!['tanggalLahir'] as Timestamp).toDate();
        }

        // Tanggal pengukuran di-set secara otomatis ke waktu saat ini
        DateTime tanggalPengukuranHariIni = DateTime.now();

        String statusStunting = _hitungStatusStunting(
          _selectedBalita!['jenisKelamin'] ?? 'Laki-laki',
          tglLahir,
          tanggalPengukuranHariIni,
          tb,
        );

        await FirebaseFirestore.instance.collection('pemeriksaan').add({
          'balitaId': _selectedBalita!['id'],
          'namaBalita': _selectedBalita!['nama'],
          'tanggal': Timestamp.fromDate(tanggalPengukuranHariIni),
          'beratBadan': bb,
          'tinggiBadan': tb,
          'lingkarKepala': lk,
          'lingkarLengan': lila,
          'statusStunting': statusStunting,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hasil pengukuran berhasil disimpan!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyimpan data: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Input Pengukuran',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Identitas Balita',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 12),

              // Kartu Pilihan Balita
              InkWell(
                onTap: _pilihBalita,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedBalita == null
                          ? Colors.grey.shade300
                          : Colors.blue.shade200,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _selectedBalita == null
                      ? Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_search_rounded,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                'Ketuk untuk mencari & memilih balita',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor:
                                  _selectedBalita!['jenisKelamin'] ==
                                      'Laki-laki'
                                  ? Colors.blue.withOpacity(0.15)
                                  : Colors.pink.withOpacity(0.15),
                              child: Icon(
                                Icons.child_care,
                                color:
                                    _selectedBalita!['jenisKelamin'] ==
                                        'Laki-laki'
                                    ? Colors.blue
                                    : Colors.pink,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedBalita!['nama'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_selectedBalita!['usia']} • ${_selectedBalita!['jenisKelamin']}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Ubah',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Hasil Pemeriksaan Fisik',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildMeasurementField(
                      controller: _bbController,
                      label: 'Berat Badan (BB)',
                      hint: 'Contoh: 10.5',
                      suffix: 'kg',
                      icon: Icons.monitor_weight_outlined,
                    ),
                    const Divider(height: 32, color: Color(0xFFF1F5F9)),
                    _buildMeasurementField(
                      controller: _tbController,
                      label: 'Tinggi Badan (TB/PB)',
                      hint: 'Contoh: 82.5',
                      suffix: 'cm',
                      icon: Icons.height_outlined,
                    ),
                    const Divider(height: 32, color: Color(0xFFF1F5F9)),
                    _buildMeasurementField(
                      controller: _lkController,
                      label: 'Lingkar Kepala (LK)',
                      hint: 'Contoh: 47.0',
                      suffix: 'cm',
                      icon: Icons.face_retouching_natural_rounded,
                    ),
                    const Divider(height: 32, color: Color(0xFFF1F5F9)),
                    _buildMeasurementField(
                      controller: _lilaController,
                      label: 'Lingkar Lengan Atas (LILA)',
                      hint: 'Contoh: 15.2',
                      suffix: 'cm',
                      icon: Icons.accessibility_new_rounded,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _simpanPengukuran,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: Colors.blue.withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Simpan Pengukuran',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurementField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black54,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontWeight: FontWeight.normal,
            ),
            prefixIcon: Icon(icon, color: Colors.blue, size: 20),
            suffixText: suffix,
            suffixStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black45,
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Wajib diisi';
            if (double.tryParse(value.replaceAll(',', '.')) == null) {
              return 'Format angka tidak valid';
            }
            return null;
          },
        ),
      ],
    );
  }
}
