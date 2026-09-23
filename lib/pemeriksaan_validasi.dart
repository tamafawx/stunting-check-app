import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pemeriksaan_validasi_informasi.dart';
import 'pemeriksaan_validasi_pilih_balita.dart';
import 'who_data_service.dart';
import 'who_growth_chart.dart';

class PemeriksaanValidasi extends StatefulWidget {
  final String? role;

  const PemeriksaanValidasi({super.key, this.role});

  @override
  State<PemeriksaanValidasi> createState() => _PemeriksaanValidasiState();
}

class _PemeriksaanValidasiState extends State<PemeriksaanValidasi> {
  Map<String, dynamic>? _selectedBalita;
  String? _selectedPemeriksaanId;

  Color get themeColor => widget.role == 'bidan' ? Colors.purple : Colors.blue;

  String _calculateAgeAtExamination(
    dynamic birthDateData,
    dynamic examDateData,
  ) {
    if (birthDateData == null || examDateData == null) return "-";

    DateTime? birthDate;
    if (birthDateData is Timestamp) {
      birthDate = birthDateData.toDate();
    } else if (birthDateData is DateTime) {
      birthDate = birthDateData;
    } else if (birthDateData is String) {
      birthDate = DateTime.tryParse(birthDateData);
    }

    DateTime? examDate;
    if (examDateData is Timestamp) {
      examDate = examDateData.toDate();
    } else if (examDateData is DateTime) {
      examDate = examDateData;
    } else if (examDateData is String) {
      examDate = DateTime.tryParse(examDateData);
    }

    if (birthDate == null || examDate == null) return "-";

    int months =
        (examDate.year - birthDate.year) * 12 +
        examDate.month -
        birthDate.month;
    if (examDate.day < birthDate.day) {
      months--;
    }

    if (months < 0) return "0 Bulan";

    int years = months ~/ 12;
    int remainingMonths = months % 12;

    if (years > 0) {
      if (remainingMonths > 0) {
        return "$years Tahun $remainingMonths Bulan";
      }
      return "$years Tahun";
    }
    return "$months Bulan";
  }

  int _getAgeInMonths(dynamic birthDateData, dynamic examDateData) {
    if (birthDateData == null || examDateData == null) return -1;
    DateTime? birthDate;
    if (birthDateData is Timestamp) {
      birthDate = birthDateData.toDate();
    } else if (birthDateData is DateTime) {
      birthDate = birthDateData;
    } else if (birthDateData is String) {
      birthDate = DateTime.tryParse(birthDateData);
    }

    DateTime? examDate;
    if (examDateData is Timestamp) {
      examDate = examDateData.toDate();
    } else if (examDateData is DateTime) {
      examDate = examDateData;
    } else if (examDateData is String) {
      examDate = DateTime.tryParse(examDateData);
    }

    if (birthDate == null || examDate == null) return -1;

    int months =
        (examDate.year - birthDate.year) * 12 +
        examDate.month -
        birthDate.month;
    if (examDate.day < birthDate.day) months--;
    return months < 0 ? 0 : months;
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
              color: themeColor,
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

  Widget _buildPemeriksaanRow(
    IconData icon,
    String label,
    String value, {
    bool isEnabled = true,
    String? status,
    bool showTooltip = true,
  }) {
    Color activeColor = (status != null && status.isNotEmpty)
        ? _getStatusColor(status)
        : themeColor;

    Color iconBgColor = isEnabled
        ? activeColor.withValues(alpha: 0.1)
        : Colors.grey.withValues(alpha: 0.1);
    Color iconColor = isEnabled ? activeColor : Colors.grey;
    Color labelColor = isEnabled ? Colors.grey[700]! : Colors.grey[500]!;
    Color valueColor = isEnabled ? Colors.black87 : Colors.grey[400]!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: labelColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
                ),
                if (showTooltip && status != null && status.isNotEmpty)
                  Tooltip(
                    message: status,
                    triggerMode: TooltipTriggerMode.tap,
                    showDuration: const Duration(seconds: 3),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    child: Icon(
                      Icons.help_outline,
                      size: 18,
                      color: _getStatusColor(status),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value, {bool isLast = false}) {
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
              color: themeColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    String s = status.toLowerCase();
    if (s.contains('sangat') ||
        s.contains('buruk') ||
        s.contains('risiko tinggi')) {
      return Colors.redAccent;
    } else if (s.contains('normal') || s.contains('aman')) {
      return Colors.green;
    } else if (s.contains('pendek') ||
        s.contains('kurang') ||
        s.contains('sefali') ||
        s.contains('tinggi') ||
        s.contains('lebih') ||
        s.contains('risiko rendah')) {
      return Colors.orange;
    }
    return themeColor;
  }

  Widget _buildMetadataStatusRow(
    String label,
    String status, {
    bool isLast = false,
    bool usePillStyle = false,
  }) {
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
              color: themeColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: usePillStyle
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : Text(
                      status,
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedianFutureRow(
    String type,
    int month,
    String gender,
    String posisi,
    String unit, {
    bool isLast = false,
  }) {
    return FutureBuilder<double?>(
      future: WhoDataService.getMedian(type, gender, month, position: posisi),
      builder: (context, snapshot) {
        String val = '-';
        if (snapshot.connectionState == ConnectionState.waiting) {
          val = '...';
        } else if (snapshot.hasData && snapshot.data != null) {
          val = '${snapshot.data!.toStringAsFixed(1)} $unit';
        }

        return _buildMetadataRow('Normal/Median', val, isLast: isLast);
      },
    );
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  Widget _buildWhoDataTableFuture(
    String type,
    int month,
    String gender,
    String posisi,
    String unit, {
    dynamic currentValueRaw,
  }) {
    return FutureBuilder<List<WhoDataRow>?>(
      future: WhoDataService.getSurroundingData(
        type,
        gender,
        month,
        position: posisi,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final dataList = snapshot.data!;
        double? currentVal = _parseDouble(currentValueRaw);

        return Column(
          children: [
            WhoGrowthChart(
              type: type,
              currentMonth: month,
              currentValue: currentVal,
              gender: gender,
              posisi: posisi,
              unit: unit,
            ),
            Container(
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowHeight: 36,
                    dataRowMinHeight: 32,
                    dataRowMaxHeight: 32,
                    headingRowColor: WidgetStateProperty.all(
                      Colors.grey.shade100,
                    ),
                    columnSpacing: 16,
                    horizontalMargin: 12,
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Umur',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          '-3 SD',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          '-2 SD',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          '-1 SD',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Median',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          '+1 SD',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          '+2 SD',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          '+3 SD',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    rows: dataList.map((row) {
                      final isCurrentMonth = row.month == month;
                      final textStyle = TextStyle(
                        fontSize: 11,
                        fontWeight: isCurrentMonth
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCurrentMonth ? themeColor : Colors.black87,
                      );
                      return DataRow(
                        color: isCurrentMonth
                            ? WidgetStateProperty.all(
                                themeColor.withValues(alpha: 0.05),
                              )
                            : null,
                        cells: [
                          DataCell(Text('${row.month} Bln', style: textStyle)),
                          DataCell(
                            Text(
                              row.sd3neg.toStringAsFixed(1),
                              style: textStyle,
                            ),
                          ),
                          DataCell(
                            Text(
                              row.sd2neg.toStringAsFixed(1),
                              style: textStyle,
                            ),
                          ),
                          DataCell(
                            Text(
                              row.sd1neg.toStringAsFixed(1),
                              style: textStyle,
                            ),
                          ),
                          DataCell(
                            Text(
                              row.median.toStringAsFixed(1),
                              style: textStyle,
                            ),
                          ),
                          DataCell(
                            Text(row.sd1.toStringAsFixed(1), style: textStyle),
                          ),
                          DataCell(
                            Text(row.sd2.toStringAsFixed(1), style: textStyle),
                          ),
                          DataCell(
                            Text(row.sd3.toStringAsFixed(1), style: textStyle),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPemeriksaanSebelumnyaCard() {
    if (_selectedBalita == null) {
      return Opacity(
        opacity: 0.6,
        child: IgnorePointer(
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
                    Icon(Icons.history, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Pemeriksaan Sebelumnya',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: null,
                  isExpanded: true,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Pilih balita terlebih dahulu',
                    labelStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  items: const [],
                  onChanged: null,
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 8),
                _buildPemeriksaanRow(
                  Icons.monitor_weight_outlined,
                  'Berat Badan',
                  '-',
                  isEnabled: false,
                ),
                _buildPemeriksaanRow(
                  Icons.height,
                  'Tinggi Badan',
                  '-',
                  isEnabled: false,
                ),
                _buildPemeriksaanRow(
                  Icons.face_retouching_natural,
                  'Lingkar Kepala',
                  '-',
                  isEnabled: false,
                ),
                _buildPemeriksaanRow(
                  Icons.accessibility_new,
                  'Lingkar Lengan',
                  '-',
                  isEnabled: false,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pemeriksaan')
          .where('balitaId', isEqualTo: _selectedBalita!['id'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        var docs = snapshot.data?.docs ?? [];
        bool hasData = docs.isNotEmpty;

        if (hasData) {
          docs.sort((a, b) {
            var dataA = a.data() as Map<String, dynamic>;
            var dataB = b.data() as Map<String, dynamic>;
            Timestamp tA = dataA['tanggal'] ?? Timestamp.now();
            Timestamp tB = dataB['tanggal'] ?? Timestamp.now();
            return tB.compareTo(tA);
          });
        }

        String? currentSelectedId;
        Map<String, dynamic>? selectedData;

        if (hasData) {
          currentSelectedId = _selectedPemeriksaanId ?? docs.first.id;
          if (!docs.any((d) => d.id == currentSelectedId)) {
            currentSelectedId = docs.first.id;
          }

          var selectedDoc = docs.firstWhere((d) => d.id == currentSelectedId);
          selectedData = selectedDoc.data() as Map<String, dynamic>;
        }

        int ageMonths = -1;
        String gender = _selectedBalita!['jenisKelamin'] ?? 'laki-laki';
        String posisi = 'berdiri';
        if (hasData && selectedData != null) {
          ageMonths = _getAgeInMonths(
            _selectedBalita!['tanggalLahir'],
            selectedData['tanggal'],
          );
          if (selectedData.containsKey('posisiUkur')) {
            posisi = selectedData['posisiUkur'];
          }
        } else {
          ageMonths = _getAgeInMonths(
            _selectedBalita!['tanggalLahir'],
            DateTime.now(),
          );
        }

        return Column(
          children: [
            Container(
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
                      Icon(
                        Icons.history,
                        color: hasData ? themeColor : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pemeriksaan Sebelumnya',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: hasData ? Colors.grey[800] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: currentSelectedId,
                    isExpanded: true,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Pilih Pemeriksaan',
                      labelStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      filled: !hasData,
                      fillColor: !hasData ? Colors.grey[100] : null,
                    ),
                    items: hasData
                        ? docs.asMap().entries.map((entry) {
                            int index = entry.key;
                            var doc = entry.value;
                            var data = doc.data() as Map<String, dynamic>;
                            String formattedDate = _formatDate(data['tanggal']);
                            int nomorPemeriksaan = docs.length - index;
                            return DropdownMenuItem<String>(
                              value: doc.id,
                              child: Text(
                                'Pemeriksaan # $nomorPemeriksaan ($formattedDate)',
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList()
                        : const [],
                    onChanged: hasData
                        ? (val) {
                            setState(() {
                              _selectedPemeriksaanId = val;
                            });
                          }
                        : null,
                  ),
                  if (!hasData) ...[
                    const SizedBox(height: 8),
                    Text(
                      '* Balita ini belum memiliki pemeriksaan sama sekali.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  if (hasData && selectedData != null) ...[
                    const SizedBox(height: 12),
                    _buildMetadataRow(
                      'ID Pemeriksaan',
                      currentSelectedId ?? '-',
                    ),
                    _buildMetadataRow(
                      'Tanggal Pemeriksaan',
                      _formatDate(selectedData['tanggal']),
                    ),
                    _buildMetadataRow(
                      'Pemeriksaan Ke',
                      docs.indexWhere((d) => d.id == currentSelectedId) != -1
                          ? (docs.length -
                                    docs.indexWhere(
                                      (d) => d.id == currentSelectedId,
                                    ))
                                .toString()
                          : '-',
                    ),
                    _buildMetadataRow(
                      'Umur (saat periksa)',
                      _calculateAgeAtExamination(
                        _selectedBalita?['tanggalLahir'],
                        selectedData['tanggal'],
                      ),
                    ),
                    _buildMetadataStatusRow(
                      'Status Anak/Balita',
                      selectedData['statusBalita'] ?? 'Aman',
                      isLast: true,
                      usePillStyle: true,
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  _buildPemeriksaanRow(
                    Icons.monitor_weight_outlined,
                    'Berat Badan',
                    hasData ? '${selectedData!['beratBadan'] ?? '-'} kg' : '-',
                    isEnabled: hasData,
                    status: hasData ? selectedData!['statusBeratBadan'] : null,
                  ),
                  _buildPemeriksaanRow(
                    Icons.height,
                    'Tinggi Badan',
                    hasData ? '${selectedData!['tinggiBadan'] ?? '-'} cm' : '-',
                    isEnabled: hasData,
                    status: hasData ? selectedData!['statusTinggiBadan'] : null,
                  ),
                  _buildPemeriksaanRow(
                    Icons.face_retouching_natural,
                    'Lingkar Kepala',
                    hasData
                        ? '${selectedData!['lingkarKepala'] ?? '-'} cm'
                        : '-',
                    isEnabled: hasData,
                    status: hasData
                        ? selectedData!['statusLingkarKepala']
                        : null,
                  ),
                  _buildPemeriksaanRow(
                    Icons.accessibility_new,
                    'Lingkar Lengan',
                    hasData
                        ? '${selectedData!['lingkarLengan'] ?? '-'} cm'
                        : '-',
                    isEnabled: hasData,
                    status: hasData
                        ? selectedData!['statusLingkarLengan']
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              Icons.monitor_weight_outlined,
              'Detail Berat Badan',
              customContent: Column(
                children: [
                  _buildPemeriksaanRow(
                    Icons.monitor_weight_outlined,
                    'Berat Badan Sekarang',
                    hasData
                        ? '${selectedData!['beratBadan'] ?? '-'} kg'
                        : '- kg',
                    isEnabled: hasData,
                    status: hasData ? selectedData!['statusBeratBadan'] : null,
                    showTooltip: false,
                  ),
                  if (hasData) ...[
                    _buildMetadataStatusRow(
                      'Status',
                      selectedData!['statusBeratBadan'] ?? 'Belum ada status',
                    ),
                    _buildMedianFutureRow(
                      'weight',
                      ageMonths,
                      gender,
                      posisi,
                      'kg',
                      isLast: true,
                    ),
                    _buildWhoDataTableFuture(
                      'weight',
                      ageMonths,
                      gender,
                      posisi,
                      'kg',
                      currentValueRaw: selectedData['beratBadan'],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              Icons.height,
              'Detail Panjang/Tinggi Badan',
              customContent: Column(
                children: [
                  _buildPemeriksaanRow(
                    Icons.height,
                    '${posisi == "berdiri" ? "Tinggi" : "Panjang"} Badan Sekarang',
                    hasData
                        ? '${selectedData!['tinggiBadan'] ?? '-'} cm'
                        : '- cm',
                    isEnabled: hasData,
                    status: hasData ? selectedData!['statusTinggiBadan'] : null,
                    showTooltip: false,
                  ),
                  if (hasData) ...[
                    _buildMetadataRow(
                      'Posisi Pengukuran',
                      posisi.isNotEmpty
                          ? '${posisi[0].toUpperCase()}${posisi.substring(1)}'
                          : 'Berdiri',
                    ),
                    _buildMetadataStatusRow(
                      'Status',
                      selectedData!['statusTinggiBadan'] ?? 'Belum ada status',
                    ),
                    _buildMedianFutureRow(
                      'height',
                      ageMonths,
                      gender,
                      posisi,
                      'cm',
                      isLast: true,
                    ),
                    _buildWhoDataTableFuture(
                      'height',
                      ageMonths,
                      gender,
                      posisi,
                      'cm',
                      currentValueRaw: selectedData['tinggiBadan'],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              Icons.face_retouching_natural,
              'Detail Lingkar Kepala',
              customContent: Column(
                children: [
                  _buildPemeriksaanRow(
                    Icons.face_retouching_natural,
                    'Lingkar Kepala Sekarang',
                    hasData
                        ? '${selectedData!['lingkarKepala'] ?? '-'} cm'
                        : '- cm',
                    isEnabled: hasData,
                    status: hasData
                        ? selectedData!['statusLingkarKepala']
                        : null,
                    showTooltip: false,
                  ),
                  if (hasData) ...[
                    _buildMetadataStatusRow(
                      'Status',
                      selectedData!['statusLingkarKepala'] ??
                          'Belum ada status',
                    ),
                    _buildMedianFutureRow(
                      'head',
                      ageMonths,
                      gender,
                      posisi,
                      'cm',
                      isLast: true,
                    ),
                    _buildWhoDataTableFuture(
                      'head',
                      ageMonths,
                      gender,
                      posisi,
                      'cm',
                      currentValueRaw: selectedData['lingkarKepala'],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              Icons.accessibility_new,
              'Detail Lingkar Lengan',
              customContent: Column(
                children: [
                  _buildPemeriksaanRow(
                    Icons.accessibility_new,
                    'Lingkar Lengan Sekarang',
                    hasData
                        ? '${selectedData!['lingkarLengan'] ?? '-'} cm'
                        : '- cm',
                    isEnabled: hasData,
                    status: hasData
                        ? selectedData!['statusLingkarLengan']
                        : null,
                    showTooltip: false,
                  ),
                  if (hasData) ...[
                    _buildMetadataStatusRow(
                      'Status',
                      selectedData!['statusLingkarLengan'] ??
                          'Belum ada status',
                    ),
                    _buildMedianFutureRow(
                      'arm',
                      ageMonths,
                      gender,
                      posisi,
                      'cm',
                      isLast: true,
                    ),
                    _buildWhoDataTableFuture(
                      'arm',
                      ageMonths,
                      gender,
                      posisi,
                      'cm',
                      currentValueRaw: selectedData['lingkarLengan'],
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailCard(
    IconData icon,
    String title, {
    Widget? customContent,
  }) {
    Widget content = Container(
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
              Icon(
                icon,
                color: _selectedBalita != null ? themeColor : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: _selectedBalita != null
                      ? Colors.grey[800]
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          customContent ??
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(
                    'Akan segera di buat',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
        ],
      ),
    );

    if (_selectedBalita == null) {
      return Opacity(opacity: 0.6, child: IgnorePointer(child: content));
    }
    return content;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Validasi Pemeriksaan',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Informasi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PemeriksaanValidasiInformasi(role: widget.role),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          InkWell(
            onTap: () async {
              final selectedBalita = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PemeriksaanValidasiPilihBalita(role: widget.role),
                ),
              );

              if (selectedBalita != null && selectedBalita is Map) {
                setState(() {
                  _selectedBalita = Map<String, dynamic>.from(selectedBalita);
                  _selectedPemeriksaanId = null;
                });
              }
            },
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
                        backgroundColor: themeColor.withValues(alpha: 0.1),
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
                                _selectedBalita!['fotoUrl'].toString().isEmpty)
                            ? Icon(
                                Icons.child_care,
                                color: themeColor,
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
                      _selectedBalita!['jenisKelamin'] == "male"
                          ? "Laki-Laki"
                          : "Perempuan",
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
          const SizedBox(height: 16),
          _buildPemeriksaanSebelumnyaCard(),
          const SizedBox(height: 16),

          Opacity(
            opacity: _selectedBalita == null ? 0.6 : 1.0,
            child: IgnorePointer(
              ignoring: _selectedBalita == null,
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
