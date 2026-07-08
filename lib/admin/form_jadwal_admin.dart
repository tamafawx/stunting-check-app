import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
                    ? 'Jadwal ditambahkan'
                    : 'Jadwal diperbarui',
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.docId == null ? "Tambah Jadwal" : "Edit Jadwal",
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _judulController,
                      decoration: const InputDecoration(
                        labelText: 'Judul / Nama Kegiatan',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _kategori,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Posyandu', 'Imunisasi']
                          .map(
                            (k) => DropdownMenuItem(value: k, child: Text(k)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _kategori = val!),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      title: const Text(
                        'Tanggal Pelaksanaan',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      subtitle: Text(
                        _tanggal == null
                            ? 'Pilih Tanggal'
                            : DateFormat('dd MMMM yyyy').format(_tanggal!),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.calendar_today,
                        color: Colors.red,
                      ),
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
                        if (picked != null) setState(() => _tanggal = picked);
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            title: const Text(
                              'Mulai',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            subtitle: Text(
                              _waktuMulai == null
                                  ? '00:00'
                                  : _waktuMulai!.format(context),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: _waktuMulai ?? TimeOfDay.now(),
                              );
                              if (time != null) {
                                setState(() => _waktuMulai = time);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            title: const Text(
                              'Selesai',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            subtitle: Text(
                              _waktuSelesai == null
                                  ? '00:00'
                                  : _waktuSelesai!.format(context),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: _waktuSelesai ?? TimeOfDay.now(),
                              );
                              if (time != null) {
                                setState(() => _waktuSelesai = time);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lokasiController,
                      decoration: const InputDecoration(
                        labelText: 'Lokasi (Cth: Balai Desa)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _keteranganController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Keterangan Tambahan (Opsional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: _simpanJadwal,
                        child: const Text(
                          "Simpan Jadwal",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
