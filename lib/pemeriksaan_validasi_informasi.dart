import 'package:flutter/material.dart';
import 'who_data_service.dart';

class PemeriksaanValidasiInformasi extends StatefulWidget {
  final String? role;

  const PemeriksaanValidasiInformasi({super.key, this.role});

  @override
  State<PemeriksaanValidasiInformasi> createState() =>
      _PemeriksaanValidasiInformasiState();
}

class _PemeriksaanValidasiInformasiState
    extends State<PemeriksaanValidasiInformasi>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color get themeColor => widget.role == 'bidan' ? Colors.purple : Colors.blue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Informasi Stunting',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: themeColor, size: 28),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Apa itu Stunting?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Stunting adalah kondisi gagal tumbuh pada anak balita (bayi di bawah 5 tahun) akibat dari kekurangan gizi kronis sehingga anak terlalu pendek untuk usianya. Kekurangan gizi terjadi sejak bayi dalam kandungan pada masa awal setelah bayi lahir, tetapi kondisi stunting baru nampak setelah bayi berusia 2 tahun.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: themeColor,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Penyebab Utama Stunting',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBulletPoint(
                          'Kurangnya asupan gizi selama masa kehamilan.',
                        ),
                        _buildBulletPoint(
                          'Kebutuhan gizi anak yang tidak tercukupi.',
                        ),
                        _buildBulletPoint(
                          'Kurangnya pengetahuan ibu mengenai gizi sebelum hamil, saat hamil, dan setelah melahirkan.',
                        ),
                        _buildBulletPoint(
                          'Terbatasnya akses pelayanan kesehatan, air bersih, dan sanitasi.',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.table_chart_outlined,
                          color: themeColor,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Tabel Z-Scores (Menurut WHO)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tabel standar deviasi berat dan tinggi badan berdasarkan usia.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 0.0),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: themeColor,
                        unselectedLabelColor: Colors.grey[400],
                        indicatorColor: themeColor,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicatorWeight: 3.0,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        tabs: const [
                          Tab(text: "Laki-Laki"),
                          Tab(text: "Perempuan"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_tabController.index == 0) ...[
                      _buildExpandableTable(
                        title: 'Tabel Panjang Badan',
                        icon: Icons.height,
                        tableWidget: _buildWhoTableDynamic(
                          'height',
                          'laki-laki',
                          0,
                          position: 'telentang',
                          headerColor: Colors.blue.shade400,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildExpandableTable(
                        title: 'Tabel Tinggi Badan',
                        icon: Icons.height,
                        tableWidget: _buildWhoTableDynamic(
                          'height',
                          'laki-laki',
                          24,
                          position: 'berdiri',
                          headerColor: Colors.blue.shade400,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildExpandableTable(
                        title: 'Tabel Berat Badan',
                        icon: Icons.monitor_weight_outlined,
                        tableWidget: _buildWhoTableDynamic(
                          'weight',
                          'laki-laki',
                          0,
                          headerColor: Colors.blue.shade400,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildExpandableTable(
                        title: 'Tabel Lingkar Kepala',
                        icon: Icons.face,
                        tableWidget: _buildWhoTableDynamic(
                          'head',
                          'laki-laki',
                          0,
                          headerColor: Colors.blue.shade400,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildExpandableTable(
                        title: 'Tabel Lingkar Lengan',
                        icon: Icons.fitness_center,
                        tableWidget: _buildWhoTableDynamic(
                          'arm',
                          'laki-laki',
                          3,
                          headerColor: Colors.blue.shade400,
                        ),
                      ),
                    ] else ...[
                      _buildExpandableTable(
                        title: 'Tabel Panjang Badan',
                        icon: Icons.height,
                        tableWidget: _buildWhoTableDynamic(
                          'height',
                          'perempuan',
                          0,
                          position: 'telentang',
                          headerColor: Colors.pink.shade300,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildExpandableTable(
                        title: 'Tabel Tinggi Badan',
                        icon: Icons.height,
                        tableWidget: _buildWhoTableDynamic(
                          'height',
                          'perempuan',
                          24,
                          position: 'berdiri',
                          headerColor: Colors.pink.shade300,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildExpandableTable(
                        title: 'Tabel Berat Badan',
                        icon: Icons.monitor_weight_outlined,
                        tableWidget: _buildWhoTableDynamic(
                          'weight',
                          'perempuan',
                          0,
                          headerColor: Colors.pink.shade300,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildExpandableTable(
                        title: 'Tabel Lingkar Kepala',
                        icon: Icons.face,
                        tableWidget: _buildWhoTableDynamic(
                          'head',
                          'perempuan',
                          0,
                          headerColor: Colors.pink.shade300,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildExpandableTable(
                        title: 'Tabel Lingkar Lengan',
                        icon: Icons.fitness_center,
                        tableWidget: _buildWhoTableDynamic(
                          'arm',
                          'perempuan',
                          3,
                          headerColor: Colors.pink.shade300,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•',
            style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableTable({
    required String title,
    required Widget tableWidget,
    required IconData icon,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: themeColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: tableWidget,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhoTableDynamic(
    String type,
    String gender,
    int targetMonth, {
    String position = "berdiri",
    Color? headerColor,
  }) {
    return FutureBuilder<List<WhoDataRow>?>(
      future: WhoDataService.getAllData(
        type,
        gender,
        targetMonth,
        position: position,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "Data tidak tersedia",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final data = snapshot.data!;
        final effectiveColor = headerColor ?? themeColor;

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: effectiveColor.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: DataTable(
              headingRowHeight: 36,
              dataRowMinHeight: 32,
              dataRowMaxHeight: 32,
              headingRowColor: WidgetStateProperty.all(
                effectiveColor.withValues(alpha: 0.15),
              ),
              columnSpacing: 16,
              horizontalMargin: 12,
              columns: [
                DataColumn(
                  label: Text(
                    'Umur\nBulan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: effectiveColor,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    '-3 SD',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: effectiveColor,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    '-2 SD',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: effectiveColor,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    '-1 SD',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: effectiveColor,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Median',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: effectiveColor,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    '1 SD',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: effectiveColor,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    '2 SD',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: effectiveColor,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    '3 SD',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: effectiveColor,
                    ),
                  ),
                ),
              ],
              rows: data.map((row) {
                const textStyle = TextStyle(
                  fontSize: 11,
                  color: Colors.black87,
                );
                return DataRow(
                  cells: [
                    DataCell(
                      Center(
                        child: Text(row.month.toString(), style: textStyle),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: Text(
                          row.sd3neg.toStringAsFixed(1),
                          style: textStyle,
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: Text(
                          row.sd2neg.toStringAsFixed(1),
                          style: textStyle,
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: Text(
                          row.sd1neg.toStringAsFixed(1),
                          style: textStyle,
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: Text(
                          row.median.toStringAsFixed(1),
                          style: textStyle,
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: Text(
                          row.sd1.toStringAsFixed(1),
                          style: textStyle,
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: Text(
                          row.sd2.toStringAsFixed(1),
                          style: textStyle,
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: Text(
                          row.sd3.toStringAsFixed(1),
                          style: textStyle,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
