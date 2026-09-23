import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'who_data_service.dart';

class WhoGrowthChart extends StatelessWidget {
  final String type;
  final int currentMonth;
  final double? currentValue;
  final String gender;
  final String posisi;
  final String unit;

  const WhoGrowthChart({
    super.key,
    required this.type,
    required this.currentMonth,
    this.currentValue,
    required this.gender,
    required this.posisi,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<WhoDataRow>?>(
      future: WhoDataService.getAllData(
        type,
        gender,
        currentMonth,
        position: posisi,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;

        // Find min and max for axes
        double minX = data.first.month.toDouble();
        double maxX = data.last.month.toDouble();

        // Let's limit the x-axis to a relevant range, e.g. currentMonth - 12 to currentMonth + 12
        // If it's a 0-5 years chart (0-60 months) it might be too squeezed.
        // The user uploaded an image showing 6 months to 2 years, but we can just show the whole range or a window.
        // Let's show a 24 month window centered on currentMonth, clamped to available data.
        double windowMinX = (currentMonth - 12).toDouble();
        double windowMaxX = (currentMonth + 12).toDouble();
        if (windowMinX < minX) {
          windowMinX = minX;
          windowMaxX = (minX + 24).clamp(minX, maxX);
        }
        if (windowMaxX > maxX) {
          windowMaxX = maxX;
          windowMinX = (maxX - 24).clamp(minX, maxX);
        }

        // Generate spots
        List<FlSpot> sd3neg = [];
        List<FlSpot> sd2neg = [];
        List<FlSpot> sd0 = [];
        List<FlSpot> sd2 = [];
        List<FlSpot> sd3 = [];

        double minY = double.infinity;
        double maxY = double.negativeInfinity;

        for (var row in data) {
          if (row.month >= windowMinX && row.month <= windowMaxX) {
            sd3neg.add(FlSpot(row.month.toDouble(), row.sd3neg));
            sd2neg.add(FlSpot(row.month.toDouble(), row.sd2neg));
            sd0.add(FlSpot(row.month.toDouble(), row.median));
            sd2.add(FlSpot(row.month.toDouble(), row.sd2));
            sd3.add(FlSpot(row.month.toDouble(), row.sd3));

            if (row.sd3neg < minY) minY = row.sd3neg;
            if (row.sd3 > maxY) maxY = row.sd3;
          }
        }

        if (currentValue != null) {
          if (currentValue! < minY) minY = currentValue!;
          if (currentValue! > maxY) maxY = currentValue!;
        }

        // Add padding to Y axis
        double yRange = maxY - minY;
        minY -= yRange * 0.1;
        maxY += yRange * 0.1;

        return Container(
          height: 300,
          margin: const EdgeInsets.only(top: 16, bottom: 8),
          padding: const EdgeInsets.only(
            right: 24,
            left: 8,
            top: 24,
            bottom: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: LineChart(
            LineChartData(
              minX: windowMinX,
              maxX: windowMaxX,
              minY: minY,
              maxY: maxY,
              lineBarsData: [
                _buildLineChartBarData(sd3, Colors.black, '-3 / 3 SD'),
                _buildLineChartBarData(sd2, Colors.red, '-2 / 2 SD'),
                _buildLineChartBarData(sd0, Colors.green, 'Median'),
                _buildLineChartBarData(sd2neg, Colors.red, ''),
                _buildLineChartBarData(sd3neg, Colors.black, ''),
                if (currentValue != null)
                  LineChartBarData(
                    spots: [FlSpot(currentMonth.toDouble(), currentValue!)],
                    color: Colors.blue,
                    barWidth: 0,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: Colors.blue,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                  ),
              ],
              betweenBarsData: [
                BetweenBarsData(
                  fromIndex: 0,
                  toIndex: 1,
                  color: Colors.red.withValues(alpha: 0.1),
                ),
                BetweenBarsData(
                  fromIndex: 1,
                  toIndex: 2,
                  color: Colors.green.withValues(alpha: 0.15),
                ),
                BetweenBarsData(
                  fromIndex: 2,
                  toIndex: 3,
                  color: Colors.green.withValues(alpha: 0.15),
                ),
                BetweenBarsData(
                  fromIndex: 3,
                  toIndex: 4,
                  color: Colors.red.withValues(alpha: 0.1),
                ),
              ],
              lineTouchData: const LineTouchData(enabled: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) {
                      if (value % 3 != 0) return const SizedBox.shrink();
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          '${value.toInt()} bln',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                getDrawingHorizontalLine: (value) =>
                    FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                getDrawingVerticalLine: (value) =>
                    FlLine(color: Colors.grey.shade200, strokeWidth: 1),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey.shade300),
              ),
              extraLinesData: ExtraLinesData(
                extraLinesOnTop: true,
                horizontalLines: [],
                verticalLines: currentValue != null
                    ? [
                        VerticalLine(
                          x: currentMonth.toDouble(),
                          color: Colors.blue.withValues(alpha: 0.5),
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        ),
                      ]
                    : [],
              ),
            ),
          ),
        );
      },
    );
  }

  LineChartBarData _buildLineChartBarData(
    List<FlSpot> spots,
    Color color,
    String label,
  ) {
    return LineChartBarData(
      spots: spots,
      isCurved: false,
      color: color,
      barWidth: 1.5,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }
}
