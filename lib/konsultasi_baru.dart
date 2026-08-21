import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'konsultasi_percakapan.dart';
import 'konsultasi_pilih_bidan.dart';

class KonsultasiBaru extends StatefulWidget {
  final String userId;
  final String fullName;

  const KonsultasiBaru({
    super.key,
    required this.userId,
    required this.fullName,
  });

  @override
  State<KonsultasiBaru> createState() => _KonsultasiBaruState();
}

class _KonsultasiBaruState extends State<KonsultasiBaru> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _pesanController = TextEditingController();

  Map<String, String>? _selectedKader;
  bool _isLoading = false;

  @override
  void dispose() {
    _judulController.dispose();
    _pesanController.dispose();
    super.dispose();
  }

  Future<void> _pilihKader() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const KonsultasiPilihBidan()),
    );

    if (result != null && result is Map<String, String>) {
      setState(() {
        _selectedKader = result;
      });
    }
  }

  Future<void> _mulaiKonsultasi() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedKader == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harap pilih bidan terlebih dahulu!'),
            backgroundColor: Colors.amber,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        String judul = _judulController.text.trim();
        String pesan = _pesanController.text.trim();

        DocumentReference chatRef = await FirebaseFirestore.instance
            .collection('konsultasi')
            .add({
              'judul': judul,
              'orangTuaId': widget.userId,
              'orangTuaName': widget.fullName,
              'kaderId': _selectedKader!['id'],
              'kaderName': _selectedKader!['name'],
              'lastMessage': pesan,
              'lastMessageTime': FieldValue.serverTimestamp(),
              'isClosed': false,
              'createdAt': FieldValue.serverTimestamp(),
            });

        await chatRef.collection('messages').add({
          'senderId': widget.userId,
          'text': pesan,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => KonsultasiPercakapanScreen(
                konsultasiId: chatRef.id,
                lawanBicaraName: _selectedKader!['name']!,
                lawanBicaraId: _selectedKader!['id']!,
                currentUserId: widget.userId,
                role: 'orang_tua',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal memulai konsultasi.'),
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
        title: const Text(
          "Mulai Konsultasi",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Konsultasi dengan Ahli",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Pilih bidan dan sampaikan pertanyaan terkait perkembangan, gizi, atau kesehatan balita Anda.",
                      style: TextStyle(color: Colors.black54, height: 1.5),
                    ),
                    const SizedBox(height: 32),

                    const Text(
                      "Pilih Bidan",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pilihKader,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedKader == null
                                ? Colors.grey.shade300
                                : Colors.green,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.support_agent_rounded,
                              color: _selectedKader == null
                                  ? Colors.grey
                                  : Colors.green,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedKader == null
                                    ? 'Ketuk untuk memilih bidan'
                                    : _selectedKader!['name']!,
                                style: TextStyle(
                                  color: _selectedKader == null
                                      ? Colors.grey[500]
                                      : Colors.black87,
                                  fontWeight: _selectedKader == null
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      "Judul Konsultasi",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _judulController,
                      decoration: InputDecoration(
                        hintText: "Contoh: Anak susah makan nasi",
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.green),
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      "Pesan Konsultasi",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _pesanController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText:
                            "Ceritakan lebih detail permasalahan yang dialami...",
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.green),
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Pesan tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _mulaiKonsultasi,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Kirim & Mulai Konsultasi",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
