import 'package:flutter/services.dart' show rootBundle;

class WhoDataRow {
  final int month;
  final double sd3neg, sd2neg, sd1neg, median, sd1, sd2, sd3;

  WhoDataRow({
    required this.month,
    required this.sd3neg,
    required this.sd2neg,
    required this.sd1neg,
    required this.median,
    required this.sd1,
    required this.sd2,
    required this.sd3,
  });
}

class WhoDataService {
  static final Map<String, Map<int, WhoDataRow>> _cache = {};

  static Future<void> preloadAll() async {}

  static Future<Map<int, WhoDataRow>?> _loadData(
    String type,
    String gender,
    String position,
    int targetMonth,
  ) async {
    String genderStr = gender.toLowerCase() == 'laki-laki' ? 'boys' : 'girls';
    String filename = '';

    if (type == 'weight') {
      filename = 'wfa_${genderStr}_0-to-5-years_zscores.csv';
    } else if (type == 'height') {
      String ageGroup = "2-to-5-years";
      if (targetMonth < 24) {
        ageGroup = "0-to-2-years";
      } else if (targetMonth == 24) {
        ageGroup = position.toLowerCase() == "berdiri"
            ? "2-to-5-years"
            : "0-to-2-years";
      }
      filename = 'lhfa_${genderStr}_${ageGroup}_zscores.csv';
    } else if (type == 'head') {
      filename = 'hcfa-$genderStr-0-5-zscores.csv';
    } else if (type == 'arm') {
      if (targetMonth >= 3) {
        filename = 'acfa-$genderStr-3-5-zscores.csv';
      } else {
        return null;
      }
    }

    if (filename.isEmpty) return null;

    if (!_cache.containsKey(filename)) {
      try {
        final csvString = await rootBundle.loadString(
          'assets/who-data-csv/$filename',
        );
        final lines = csvString.split('\n');

        if (lines.isEmpty) return null;

        final headers = lines.first.split(',');
        int idxMonth = -1,
            idxSd3n = -1,
            idxSd2n = -1,
            idxSd1n = -1,
            idxSd0 = -1,
            idxSd1 = -1,
            idxSd2 = -1,
            idxSd3 = -1;

        for (int i = 0; i < headers.length; i++) {
          final h = headers[i].trim().toLowerCase();
          if (h == 'month') {
            idxMonth = i;
          } else if (h == 'sd3neg') {
            idxSd3n = i;
          } else if (h == 'sd2neg') {
            idxSd2n = i;
          } else if (h == 'sd1neg') {
            idxSd1n = i;
          } else if (h == 'sd0' || h == 'm') {
            idxSd0 = i;
          } else if (h == 'sd1') {
            idxSd1 = i;
          } else if (h == 'sd2') {
            idxSd2 = i;
          } else if (h == 'sd3') {
            idxSd3 = i;
          }
        }

        if (idxMonth == -1 || idxSd0 == -1) {
          // print(
          //   'WHO Load Error for $filename: Missing columns! Month: $idxMonth, SD0: $idxSd0',
          // );
          return null;
        }

        Map<int, WhoDataRow> dataMap = {};
        for (int i = 1; i < lines.length; i++) {
          final row = lines[i].split(',');
          if (row.length > idxSd0) {
            final mVal = int.tryParse(row[idxMonth].trim());
            if (mVal != null) {
              dataMap[mVal] = WhoDataRow(
                month: mVal,
                sd3neg: (idxSd3n != -1 && row.length > idxSd3n)
                    ? (double.tryParse(row[idxSd3n].trim()) ?? 0.0)
                    : 0.0,
                sd2neg: (idxSd2n != -1 && row.length > idxSd2n)
                    ? (double.tryParse(row[idxSd2n].trim()) ?? 0.0)
                    : 0.0,
                sd1neg: (idxSd1n != -1 && row.length > idxSd1n)
                    ? (double.tryParse(row[idxSd1n].trim()) ?? 0.0)
                    : 0.0,
                median: (idxSd0 != -1 && row.length > idxSd0)
                    ? (double.tryParse(row[idxSd0].trim()) ?? 0.0)
                    : 0.0,
                sd1: (idxSd1 != -1 && row.length > idxSd1)
                    ? (double.tryParse(row[idxSd1].trim()) ?? 0.0)
                    : 0.0,
                sd2: (idxSd2 != -1 && row.length > idxSd2)
                    ? (double.tryParse(row[idxSd2].trim()) ?? 0.0)
                    : 0.0,
                sd3: (idxSd3 != -1 && row.length > idxSd3)
                    ? (double.tryParse(row[idxSd3].trim()) ?? 0.0)
                    : 0.0,
              );
            }
          }
        }
        _cache[filename] = dataMap;
      } catch (e) {
        // print('WHO Load Error for $filename: $e');
        return null;
      }
    }
    return _cache[filename];
  }

  static Future<double?> getMedian(
    String type,
    String gender,
    int month, {
    String position = "berdiri",
  }) async {
    final data = await _loadData(type, gender, position, month);
    return data?[month]?.median;
  }

  static Future<List<WhoDataRow>?> getSurroundingData(
    String type,
    String gender,
    int month, {
    String position = "berdiri",
  }) async {
    final data = await _loadData(type, gender, position, month);
    if (data == null) return null;

    List<WhoDataRow> result = [];
    if (data.containsKey(month - 1)) result.add(data[month - 1]!);
    if (data.containsKey(month)) result.add(data[month]!);
    if (data.containsKey(month + 1)) result.add(data[month + 1]!);

    return result.isNotEmpty ? result : null;
  }

  static Future<List<WhoDataRow>?> getAllData(
    String type,
    String gender,
    int month, {
    String position = "berdiri",
  }) async {
    final data = await _loadData(type, gender, position, month);
    if (data == null) return null;

    final list = data.values.toList();
    list.sort((a, b) => a.month.compareTo(b.month));
    return list;
  }
}

