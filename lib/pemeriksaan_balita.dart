// Halaman untuk pengukuran/perhitungan balita dari berat badan,
// tinggi badan, lingkar kepala, dan lingkar lengan atas.

// Role yang dapat akses:
// - Kader

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'pemeriksaan_cari_balita.dart';

class InputPengukuran extends StatefulWidget {
  const InputPengukuran({super.key});

  @override
  State<InputPengukuran> createState() => _InputPengukuranState();
}

class _InputPengukuranState extends State<InputPengukuran> {
  final _formKey = GlobalKey<FormState>();

  Map<String, dynamic>? _selectedBalita;

  final TextEditingController _bbController = TextEditingController();
  final TextEditingController _tbController = TextEditingController();
  final TextEditingController _lkController = TextEditingController();
  final TextEditingController _lilaController = TextEditingController();
  bool _isLoading = false;
  String _posisiUkurTB = 'Berdiri';

  int get _umurBulan {
    if (_selectedBalita == null || _selectedBalita!['tanggalLahir'] == null) {
      return -1;
    }
    DateTime tglLahir = (_selectedBalita!['tanggalLahir'] as Timestamp)
        .toDate();
    DateTime now = DateTime.now();
    int months = (now.year - tglLahir.year) * 12 + now.month - tglLahir.month;
    if (now.day < tglLahir.day) {
      months--;
    }
    return months;
  }

  @override
  void dispose() {
    _bbController.dispose();
    _tbController.dispose();
    _lkController.dispose();
    _lilaController.dispose();
    super.dispose();
  }

  String _formatDate(dynamic dateData) {
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

  Widget _buildInfoRow(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
              ),
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pilihBalita() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PilihBalitaPemeriksaan()),
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
        double lila = _lilaController.text.isEmpty
            ? 0.0
            : double.parse(_lilaController.text.replaceAll(',', '.'));

        DateTime tanggalPengukuranHariIni = DateTime.now();

        await FirebaseFirestore.instance.collection('pemeriksaan').add({
          'balitaId': _selectedBalita!['id'],
          'namaBalita': _selectedBalita!['nama'],
          'tanggal': Timestamp.fromDate(tanggalPengukuranHariIni),
          'beratBadan': bb,
          'tinggiBadan': tb,
          'lingkarKepala': lk,
          'lingkarLengan': lila,
          'umurBulan': _umurBulan,
          'jenisKelamin': _selectedBalita!['jenisKelamin'] ?? 'Laki-laki',
          'posisiUkurTB': _umurBulan < 24
              ? 'Berbaring'
              : (_umurBulan > 24 ? 'Berdiri' : _posisiUkurTB),
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
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: _pilihBalita,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.blue.withValues(alpha: 0.1),
                            backgroundImage:
                                _selectedBalita != null &&
                                    _selectedBalita!['fotoUrl'] != null &&
                                    _selectedBalita!['fotoUrl']
                                        .toString()
                                        .isNotEmpty
                                ? NetworkImage(_selectedBalita!['fotoUrl'])
                                : null,
                            child:
                                (_selectedBalita == null ||
                                    _selectedBalita!['fotoUrl'] == null ||
                                    _selectedBalita!['fotoUrl']
                                        .toString()
                                        .isEmpty)
                                ? const Icon(
                                    Icons.child_care,
                                    color: Colors.blue,
                                    size: 32,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedBalita != null
                                      ? 'Balita Terpilih'
                                      : 'Pilih Balita',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedBalita != null
                                      ? _selectedBalita!['nama'] ?? 'Tanpa Nama'
                                      : 'Ketuk untuk memilih balita',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (_selectedBalita != null &&
                                    _selectedBalita!['id'] != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    "${_selectedBalita!['id']}",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                      if (_selectedBalita != null) ...[
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          'Jenis Kelamin',
                          _selectedBalita!['jenisKelamin'] ?? '-',
                        ),
                        _buildInfoRow(
                          'Tanggal Lahir',
                          _formatDate(_selectedBalita!['tanggalLahir']),
                        ),
                        _buildInfoRow('Usia', _selectedBalita!['usia'] ?? '-'),
                        _buildInfoRow(
                          'Nama Ortu',
                          _selectedBalita!['namaOrtu'] ?? '-',
                          isLast: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              if (_selectedBalita == null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 48,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(color: Colors.blue.shade50, width: 2),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.child_care_rounded,
                          size: 64,
                          color: Colors.blue.shade400,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Belum Ada Balita Terpilih',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Silahkan cari dan pilih data balita terlebih dahulu untuk mulai mengisi form hasil pengukuran.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                const Text(
                  'Form Input Pengukuran',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMeasurementField(
                  controller: _tbController,
                  label: 'Tinggi Badan (TB/PB)',
                  hint: 'Contoh: 82.5',
                  suffix: 'cm',
                  icon: Icons.height_outlined,
                  bottomWidget: (_selectedBalita != null && _umurBulan >= 0)
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(height: 32, color: Colors.black12),
                            const Text(
                              'Posisi Pengukuran:',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_umurBulan == 24)
                              Row(
                                children: [
                                  Expanded(
                                    child: ChoiceChip(
                                      label: const Center(
                                        child: Text('Berdiri'),
                                      ),
                                      selected: _posisiUkurTB == 'Berdiri',
                                      selectedColor: Colors.blue.withValues(
                                        alpha: 0.2,
                                      ),
                                      backgroundColor: Colors.white,
                                      onSelected: (val) {
                                        if (val) {
                                          setState(
                                            () => _posisiUkurTB = 'Berdiri',
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ChoiceChip(
                                      label: const Center(
                                        child: Text('Berbaring'),
                                      ),
                                      selected: _posisiUkurTB == 'Berbaring',
                                      selectedColor: Colors.blue.withValues(
                                        alpha: 0.2,
                                      ),
                                      backgroundColor: Colors.white,
                                      onSelected: (val) {
                                        if (val) {
                                          setState(
                                            () => _posisiUkurTB = 'Berbaring',
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              )
                            else if (_umurBulan < 24)
                              SizedBox(
                                width: double.infinity,
                                child: ChoiceChip(
                                  label: const Center(child: Text('Berbaring')),
                                  selected: true,
                                  selectedColor: Colors.blue.withValues(
                                    alpha: 0.2,
                                  ),
                                  onSelected: (_) {},
                                ),
                              )
                            else if (_umurBulan > 24)
                              SizedBox(
                                width: double.infinity,
                                child: ChoiceChip(
                                  label: const Center(child: Text('Berdiri')),
                                  selected: true,
                                  selectedColor: Colors.blue.withValues(
                                    alpha: 0.2,
                                  ),
                                  onSelected: (_) {},
                                ),
                              ),
                            const Divider(height: 32, color: Colors.black12),
                            Text(
                              _umurBulan < 24
                                  ? '* Balita berusia di bawah 2 tahun (24 bulan). Silakan ukur dan isi panjang badan balita dengan posisi berbaring.'
                                  : _umurBulan > 24
                                  ? '* Balita berusia di atas 2 tahun (24 bulan). Silakan ukur dan isi tinggi badan balita dengan posisi berdiri.'
                                  : '* Balita tepat berusia 2 tahun (24 bulan). Pengukuran dapat dilakukan dengan posisi berbaring ataupun berdiri. Sebagai rekomendasi, silakan ukur dengan posisi berdiri agar mendapatkan hasil yang lebih akurat.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                                fontStyle: FontStyle.italic,
                                height: 1.3,
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                _buildMeasurementField(
                  controller: _bbController,
                  label: 'Berat Badan (BB)',
                  hint: 'Contoh: 10.5',
                  suffix: 'kg',
                  icon: Icons.monitor_weight_outlined,
                ),
                const SizedBox(height: 16),
                _buildMeasurementField(
                  controller: _lkController,
                  label: 'Lingkar Kepala (LK)',
                  hint: 'Contoh: 47.0',
                  suffix: 'cm',
                  icon: Icons.face_retouching_natural_rounded,
                ),
                const SizedBox(height: 16),
                _buildMeasurementField(
                  controller: _lilaController,
                  label: 'Lingkar Lengan Atas (LILA)',
                  hint: 'Contoh: 15.2',
                  suffix: 'cm',
                  icon: Icons.accessibility_new_rounded,
                  isEnabledOverride: _selectedBalita != null && _umurBulan >= 3,
                  bottomWidget: _selectedBalita != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(height: 32, color: Colors.black12),
                            Text(
                              _umurBulan < 3
                                  ? '* Balita berusia di bawah 3 bulan. Pengukuran Lingkar Lengan Atas (LiLA) tidak diperlukan.'
                                  : '* Balita berusia 3 bulan ke atas. Pengukuran Lingkar Lengan Atas (LiLA) dapat dilakukan.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                                fontStyle: FontStyle.italic,
                                height: 1.3,
                              ),
                            ),
                          ],
                        )
                      : null,
                ),

                const SizedBox(height: 40),

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
                      shadowColor: Colors.blue.withValues(alpha: 0.4),
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
    Widget? bottomWidget,
    bool? isEnabledOverride,
  }) {
    final bool isEnabled = isEnabledOverride ?? (_selectedBalita != null);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isEnabled ? Colors.white : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isEnabled ? Colors.black54 : Colors.grey[500],
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          FormField<String>(
            initialValue: controller.text,
            validator: (value) {
              if (!isEnabled) return null;
              if (value == null || value.isEmpty) {
                return 'Pengukuran wajib diisi.';
              }
              if (double.tryParse(value.replaceAll(',', '.')) == null) {
                return 'Format angka tidak valid.';
              }
              return null;
            },
            builder: (FormFieldState<String> state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    enabled: isEnabled,
                    controller: controller,
                    onChanged: (val) => state.didChange(val),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isEnabled ? Colors.black : Colors.grey,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontWeight: FontWeight.normal,
                      ),
                      prefixIcon: Icon(
                        icon,
                        color: isEnabled ? Colors.blue : Colors.grey,
                        size: 20,
                      ),
                      suffixText: suffix,
                      suffixStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isEnabled ? Colors.black45 : Colors.grey,
                      ),
                      filled: true,
                      fillColor: isEnabled ? Colors.grey[50] : Colors.grey[300],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                    ),
                  ),
                  if (state.hasError) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 18,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.errorText ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          if (bottomWidget != null) ...[
            const SizedBox(height: 16),
            bottomWidget,
          ],
        ],
      ),
    );
  }
}
