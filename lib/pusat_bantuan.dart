import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PusatBantuan extends StatelessWidget {
  final String role;

  const PusatBantuan({super.key, required this.role});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> _launchWebsite() async {
    final String websiteUrl = "https://tamafawx.com/";
    _launchUrl(websiteUrl);
  }

  Future<void> _launchWhatsApp() async {
    final String waUrl = "https://wa.me/6285175205254";
    _launchUrl(waUrl);
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (MapEntry<String, String> e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }

  LinearGradient _getRoleGradient(String currentRole) {
    switch (currentRole.toLowerCase()) {
      case 'admin':
        return const LinearGradient(
          colors: [Color(0xFFD32F2F), Color(0xFFFF5252)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'kader':
        return const LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'bidan':
        return const LinearGradient(
          colors: [Color(0xFF7B1FA2), Color(0xFFAB47BC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'orang-tua':
        return const LinearGradient(
          colors: [Color(0xFF388E3C), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Colors.grey, Colors.blueGrey],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _getMainThemeColor(String currentRole) {
    switch (currentRole.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'kader':
        return Colors.blue;
      case 'bidan':
        return Colors.purple;
      case 'orang-tua':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgGradient = _getRoleGradient(role);
    final themeColor = _getMainThemeColor(role);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Pusat Bantuan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: bgGradient),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "PERTANYAAN UMUM",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildFaqItem(
                          question: "Aplikasi apa sih ini?",
                          answer:
                              "Ini adalah aplikasi sistem informasi e-Posyandu untuk membantu memantau tumbuh kembang balita dan mencegah stunting secara digital.",
                          themeColor: themeColor,
                        ),
                        _buildDivider(),
                        _buildFaqItem(
                          question:
                              "Siapa saja yang bisa menggunakan aplikasi ini?",
                          answer:
                              "Aplikasi ini ditujukan untuk Orang Tua/Wali, Bidan Desa, Kader Posyandu, dan Admin Pusat.",
                          themeColor: themeColor,
                        ),
                        _buildDivider(),
                        _buildFaqItem(
                          question: "Bagaimana cara melihat jadwal posyandu?",
                          answer:
                              "Anda dapat melihat jadwal posyandu melalui menu Jadwal pada halaman beranda Anda.",
                          themeColor: themeColor,
                        ),
                        _buildDivider(),
                        _buildFaqItem(
                          question:
                              "Apakah data saya beserta balita saya aman?",
                          answer:
                              "Ya, kami menjaga kerahasiaan data anak Anda. Hanya petugas berwenang dan Anda yang bisa melihatnya.",
                          themeColor: themeColor,
                        ),
                        _buildDivider(),
                        _buildFaqItem(
                          question: "Bagaimana jika saya lupa kata sandi?",
                          answer:
                              "Anda bisa menghubungi admin melalui kontak di bawah halaman ini untuk meminta bantuan reset kata sandi atau memperbarui data.",
                          themeColor: themeColor,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    "HUBUNGI KAMI",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildContactRow(
                          icon: Icons.email_rounded,
                          title: "Website Resmi",
                          subtitle: "https://tamafawx.com/",
                          iconColor: const Color(0xFF1E88E5),
                          onTap: _launchWebsite,
                        ),
                        _buildDivider(),
                        _buildContactRow(
                          icon: Icons.message_rounded,
                          title: "Chat WhatsApp",
                          subtitle: "+62 851-7520-5254",
                          iconColor: const Color(0xFF43A047),
                          onTap: _launchWhatsApp,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 20,
      endIndent: 20,
      color: Color(0xFFF1F5F9),
    );
  }

  Widget _buildFaqItem({
    required String question,
    required String answer,
    required Color themeColor,
    bool isLast = false,
  }) {
    return Theme(
      data: ThemeData(dividerColor: Colors.transparent),
      child: ExpansionTile(
        iconColor: themeColor,
        collapsedIconColor: const Color(0xFF94A3B8),
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF334155),
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: isLast ? 16 : 8,
            ),
            child: Text(
              answer,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
