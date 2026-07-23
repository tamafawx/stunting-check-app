// Halaman untuk admin menambahkan atau mengedit jadwal kegiatan.
// Desain modern dengan OpenStreetMap (flutter_map).
// Role yang dapat akses:
// - Admin

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class FormJadwalAdminScreen extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? data;

  const FormJadwalAdminScreen({super.key, this.docId, this.data});

  @override
  State<FormJadwalAdminScreen> createState() => _FormJadwalAdminScreenState();
}

class _FormJadwalAdminScreenState extends State<FormJadwalAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _lokasiController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();

  String _kategori = 'Posyandu';
  DateTime? _tanggal;
  TimeOfDay? _waktuMulai;
  TimeOfDay? _waktuSelesai;
  bool _isLoading = false;

  // OpenStreetMap State
  LatLng? _selectedLocation;
  final LatLng _defaultLocation = const LatLng(-6.8898, 109.6746); // Pekalongan

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      _judulController.text = widget.data!['judul'] ?? '';
      _lokasiController.text = widget.data!['lokasi'] ?? '';
      _keteranganController.text = widget.data!['keterangan'] ?? '';
      _kategori = widget.data!['kategori'] ?? 'Posyandu';

      if (widget.data!['tanggal'] != null) {
        _tanggal = (widget.data!['tanggal'] as Timestamp).toDate();
      }
      if (widget.data!['waktuMulai'] != null) {
        var parts = widget.data!['waktuMulai'].toString().split(':');
        _waktuMulai = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
      if (widget.data!['waktuSelesai'] != null) {
        var parts = widget.data!['waktuSelesai'].toString().split(':');
        _waktuSelesai = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }

      if (widget.data!['latitude'] != null &&
          widget.data!['longitude'] != null) {
        _selectedLocation = LatLng(
          widget.data!['latitude'],
          widget.data!['longitude'],
        );
      }
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _lokasiController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _simpanJadwal() async {
    if (_formKey.currentState!.validate()) {
      if (_tanggal == null || _waktuMulai == null || _waktuSelesai == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pastikan Tanggal dan Waktu telah diisi'),
            backgroundColor: Colors.amber,
          ),
        );
        return;
      }

      if (_selectedLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harap ketuk peta untuk memilih lokasi!'),
            backgroundColor: Colors.amber,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        String wMulai =
            '${_waktuMulai!.hour.toString().padLeft(2, '0')}:${_waktuMulai!.minute.toString().padLeft(2, '0')}';
        String wSelesai =
            '${_waktuSelesai!.hour.toString().padLeft(2, '0')}:${_waktuSelesai!.minute.toString().padLeft(2, '0')}';

        Map<String, dynamic> jadwalData = {
          'judul': _judulController.text.trim(),
          'kategori': _kategori,
          'tanggal': Timestamp.fromDate(_tanggal!),
          'waktuMulai': wMulai,
          'waktuSelesai': wSelesai,
          'lokasi': _lokasiController.text.trim(),
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
          'keterangan': _keteranganController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (widget.docId == null) {
          jadwalData['createdAt'] = FieldValue.serverTimestamp();
          await FirebaseFirestore.instance.collection('jadwal').add(jadwalData);
        } else {
          await FirebaseFirestore.instance
              .collection('jadwal')
              .doc(widget.docId)
              .update(jadwalData);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.docId == null
                    ? 'Jadwal berhasil ditambahkan'
                    : 'Jadwal berhasil diperbarui',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menyimpan jadwal'),
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          widget.docId == null ? "Tambah Jadwal Baru" : "Edit Jadwal",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFD32F2F), Color(0xFFFF5252)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      "INFORMASI KEGIATAN",
                      Icons.info_outline_rounded,
                    ),
                    _buildCardWrapper(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _judulController,
                            decoration: _inputStyle(
                              label: 'Judul / Nama Kegiatan',
                              icon: Icons.event_note_rounded,
                            ),
                            validator: (value) =>
                                value!.isEmpty ? 'Judul wajib diisi' : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _kategori,
                            decoration: _inputStyle(
                              label: 'Kategori Kegiatan',
                              icon: Icons.category_rounded,
                            ),
                            items: ['Posyandu', 'Imunisasi']
                                .map(
                                  (k) => DropdownMenuItem(
                                    value: k,
                                    child: Text(k),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _kategori = val!),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _keteranganController,
                            maxLines: 3,
                            decoration: _inputStyle(
                              label: 'Keterangan Tambahan (Ops.',
                              icon: Icons.description_rounded,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      "WAKTU PELAKSANAAN",
                      Icons.access_time_rounded,
                    ),
                    _buildCardWrapper(
                      child: Column(
                        children: [
                          _buildDateTimePicker(
                            title: 'Tanggal Pelaksanaan',
                            value: _tanggal == null
                                ? 'Pilih Tanggal'
                                : DateFormat('dd MMMM yyyy').format(_tanggal!),
                            icon: Icons.calendar_month_rounded,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _tanggal ?? DateTime.now(),
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 365),
                                ),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (picked != null)
                                setState(() => _tanggal = picked);
                            },
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDateTimePicker(
                                  title: 'Waktu Mulai',
                                  value: _waktuMulai == null
                                      ? '--:--'
                                      : _waktuMulai!.format(context),
                                  icon: Icons.schedule_rounded,
                                  onTap: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime:
                                          _waktuMulai ?? TimeOfDay.now(),
                                    );
                                    if (time != null)
                                      setState(() => _waktuMulai = time);
                                  },
                                ),
                              ),
                              Container(
                                height: 40,
                                width: 1,
                                color: Colors.grey[200],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDateTimePicker(
                                  title: 'Waktu Selesai',
                                  value: _waktuSelesai == null
                                      ? '--:--'
                                      : _waktuSelesai!.format(context),
                                  icon: Icons.update_rounded,
                                  onTap: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime:
                                          _waktuSelesai ?? TimeOfDay.now(),
                                    );
                                    if (time != null)
                                      setState(() => _waktuSelesai = time);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader("LOKASI & PETA", Icons.map_rounded),
                    _buildCardWrapper(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _lokasiController,
                            decoration: _inputStyle(
                              label: 'Nama Lokasi (Cth: Balai Desa X)',
                              icon: Icons.location_city_rounded,
                            ),
                            validator: (value) => value!.isEmpty
                                ? 'Nama lokasi wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 250,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCenter:
                                      _selectedLocation ?? _defaultLocation,
                                  initialZoom: 15.0,
                                  onTap: (tapPosition, point) {
                                    setState(() {
                                      _selectedLocation = point;
                                    });
                                  },
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName:
                                        'com.example.posyandu',
                                  ),
                                  if (_selectedLocation != null)
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: _selectedLocation!,
                                          width: 50,
                                          height: 50,
                                          child: const Icon(
                                            Icons.location_on_rounded,
                                            color: Colors.red,
                                            size: 50,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.touch_app_rounded,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  "Ketuk (tap) di peta untuk menentukan koordinat secara akurat.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100), // Spacing for floating button
                  ],
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _isLoading
          ? const SizedBox.shrink()
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 6,
                  shadowColor: Colors.red.withValues(alpha: 0.5),
                ),
                onPressed: _simpanJadwal,
                child: const Text(
                  "Simpan Jadwal",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
    );
  }

  InputDecoration _inputStyle({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.red),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.red),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardWrapper({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDateTimePicker({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
