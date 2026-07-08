import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatKonsultasiBidan extends StatefulWidget {
  final String konsultasiId;
  final String lawanBicaraName;
  final String currentUserId;

  const ChatKonsultasiBidan({
    super.key,
    required this.konsultasiId,
    required this.lawanBicaraName,
    required this.currentUserId,
  });

  @override
  State<ChatKonsultasiBidan> createState() => _ChatKonsultasiBidanState();
}

class _ChatKonsultasiBidanState extends State<ChatKonsultasiBidan> {
  final TextEditingController _msgController = TextEditingController();

  Future<void> _sendMessage() async {
    String text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();

    try {
      // Menambah data pesan
      await FirebaseFirestore.instance
          .collection('konsultasi')
          .doc(widget.konsultasiId)
          .collection('messages')
          .add({
            'senderId': widget.currentUserId,
            'text': text,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Mengupdate lastMessage pada dokumen induk
      await FirebaseFirestore.instance
          .collection('konsultasi')
          .doc(widget.konsultasiId)
          .update({
            'lastMessage': text,
            'lastMessageTime': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint("Gagal mengirim pesan: $e");
    }
  }

  Future<void> _tutupKonsultasi() async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Tutup Konsultasi"),
            content: const Text(
              "Apakah Anda yakin ingin menyelesaikan dan menutup sesi konsultasi ini? Anda dan Orang Tua tidak akan bisa mengirim pesan lagi.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "Batal",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Tutup Sesi",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        await FirebaseFirestore.instance
            .collection('konsultasi')
            .doc(widget.konsultasiId)
            .update({'isClosed': true});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Konsultasi berhasil ditutup.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menutup konsultasi.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.lawanBicaraName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue, // Tema Kader
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Mengawasi perubahan dokumen secara real-time pada AppBar
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('konsultasi')
                .doc(widget.konsultasiId)
                .snapshots(),
            builder: (context, snapshot) {
              bool isClosed = false;
              if (snapshot.hasData && snapshot.data!.exists) {
                var data = snapshot.data!.data() as Map<String, dynamic>?;
                if (data != null) {
                  isClosed = data['isClosed'] == true;
                }
              }
              if (isClosed)
                return const SizedBox(); // Sembunyikan jika sudah ditutup

              return IconButton(
                icon: const Icon(Icons.check_circle_outline_rounded),
                tooltip: 'Tutup Konsultasi',
                onPressed: _tutupKonsultasi,
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('konsultasi')
            .doc(widget.konsultasiId)
            .snapshots(),
        builder: (context, docSnapshot) {
          bool isClosed = false;
          if (docSnapshot.hasData && docSnapshot.data!.exists) {
            var data = docSnapshot.data!.data() as Map<String, dynamic>?;
            if (data != null) {
              isClosed = data['isClosed'] == true;
            }
          }

          return Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('konsultasi')
                      .doc(widget.konsultasiId)
                      .collection('messages')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.blue),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'Belum ada pesan.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      );
                    }

                    var messages = snapshot.data!.docs;

                    return ListView.builder(
                      reverse: true, // Auto scroll to bottom behavior
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        var data =
                            messages[index].data() as Map<String, dynamic>;
                        bool isMe = data['senderId'] == widget.currentUserId;

                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: isMe
                                    ? const Radius.circular(16)
                                    : const Radius.circular(4),
                                bottomRight: isMe
                                    ? const Radius.circular(4)
                                    : const Radius.circular(16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              data['text'] ?? '',
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Menampilkan input chat HANYA jika konsultasi belum ditutup
              if (isClosed)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[300],
                  child: const Text(
                    'Konsultasi telah diselesaikan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _msgController,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            decoration: InputDecoration(
                              hintText: "Ketik balasan...",
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
