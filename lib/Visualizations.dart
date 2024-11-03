import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:thesis_nlp_app/services/firestore_service.dart';

class Visualizations extends StatelessWidget {
  const Visualizations({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Visualizations'),
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder<Map<String, int>>(
        future: _fetchData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final booksCount = data['books'] ?? 0;
          final thesesCount = data['theses'] ?? 0;
          final maxYValue = (thesesCount > booksCount ? thesesCount : booksCount).toDouble();
          final gridInterval = maxYValue / 4;

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildChartContainer(
                      title: 'Books vs Theses',
                      icon: Icons.bar_chart,
                      chart: _buildBooksVsThesesChart(booksCount, thesesCount, maxYValue, gridInterval),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatContainer('Number of Books: $booksCount'),
                        _buildStatContainer('Number of Theses: $thesesCount'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildChartContainer(
                      title: 'Book Categories',
                      icon: Icons.book,
                      chart: BookCategoryChart(),
                    ),
                    const SizedBox(height: 16),

                    _buildChartContainer(
                      title: 'Thesis Categories',
                      icon: Icons.book,
                      chart: ThesisCategoryChart(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, int>> _fetchData() async {
    final firestoreService = FirestoreService();
    final booksCount = await firestoreService.getBooksCount();
    final thesesCount = await firestoreService.getThesesCount();

    return {
      'books': booksCount,
      'theses': thesesCount,
    };
  }

  Widget _buildChartContainer({required String title, required IconData icon, required Widget chart}) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 22),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(child: chart),
          ],
        ),
      ),
    );
  }

  Widget _buildBooksVsThesesChart(int booksCount, int thesesCount, double maxYValue, double gridInterval) {
    return BarChart(
      BarChartData(
        maxY: maxYValue,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String title = group.x == 0 ? 'Books' : 'Theses';
              return BarTooltipItem(
                '$title\n${rod.toY}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(value.toInt() == 0 ? 'Books' : 'Theses', style: const TextStyle(color: Colors.white));
              },
              reservedSize: 32,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: gridInterval,
              getTitlesWidget: (value, meta) {
                final displayValue = value >= 1000 ? '${(value / 1000).toStringAsFixed(1)}K' : value.toStringAsFixed(0);
                return Text(displayValue, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
              },
              reservedSize: 42,
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [BarChartRodData(toY: booksCount.toDouble(), color: Colors.yellow, width: 20)],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [BarChartRodData(toY: thesesCount.toDouble(), color: Colors.red, width: 20)],
          ),
        ],
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          horizontalInterval: gridInterval,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withOpacity(0.2), strokeWidth: 1),
        ),
      ),
    );
  }

  Widget _buildStatContainer(String text) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class BookCategoryChart extends StatelessWidget {
  final FirestoreService firestoreService = FirestoreService();
  final List<Color> categoryColors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.pink,
    Colors.cyan,
    Colors.brown,
  ];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: fetchCategoryData('books'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final categoryCounts = snapshot.data ?? List.filled(10, 0);
        final maxCategoryCount = categoryCounts.isNotEmpty ? categoryCounts.reduce((a, b) => a > b ? a : b) : 1;

        return Column(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                for (int i = 0; i < categoryColors.length; i++)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: categoryColors[i], size: 10),
                      const SizedBox(width: 4),
                      Text(
                        [
                          'General', 'Philosophy', 'Religion', 'Soc. Sci.', 'Language',
                          'Science', 'Tech', 'Arts', 'Literature', 'History'
                        ][i],
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
              ],
            ),
            Expanded(
              child: BarChart(
                BarChartData(
                  maxY: maxCategoryCount.toDouble(),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final categories = [
                          'General Works', 'Philosophy', 'Religion', 'Social Sciences', 'Language',
                          'Science', 'Technology', 'Arts', 'Literature', 'History'
                        ];
                        return BarTooltipItem(
                          '${categories[group.x]}\n${rod.toY.toInt()}',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 || value == maxCategoryCount / 2 || value == maxCategoryCount) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(categoryCounts.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: categoryCounts[i].toDouble(),
                          color: categoryColors[i],
                          width: 20,
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxCategoryCount.toDouble(),
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                      ],
                    );
                  }),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    horizontalInterval: maxCategoryCount / 2,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.white.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<List<int>> fetchCategoryData(String type) async {
    final counts = await Future.wait([
      firestoreService.getCountByClassificationRange(type, '0.0', '99.99'),
      firestoreService.getCountByClassificationRange(type, '100.0', '199.99'),
      firestoreService.getCountByClassificationRange(type, '200.0', '299.99'),
      firestoreService.getCountByClassificationRange(type, '300.0', '399.99'),
      firestoreService.getCountByClassificationRange(type, '400.0', '499.99'),
      firestoreService.getCountByClassificationRange(type, '500.0', '599.99'),
      firestoreService.getCountByClassificationRange(type, '600.0', '699.99'),
      firestoreService.getCountByClassificationRange(type, '700.0', '799.99'),
      firestoreService.getCountByClassificationRange(type, '800.0', '899.99'),
      firestoreService.getCountByClassificationRange(type, '900.0', '999.99'),
    ]);

    return counts.map((count) => count ?? 0).toList();
  }
}

class ThesisCategoryChart extends StatelessWidget {
  final FirestoreService firestoreService = FirestoreService();
  final List<Color> categoryColors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.pink,
    Colors.cyan,
    Colors.brown,
  ];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: fetchThesisCategoryData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final categoryCounts = snapshot.data ?? List.filled(10, 0);
        final maxCategoryCount = categoryCounts.isNotEmpty ? categoryCounts.reduce((a, b) => a > b ? a : b) : 1;

        return Column(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                for (int i = 0; i < categoryColors.length; i++)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: categoryColors[i], size: 10),
                      const SizedBox(width: 4),
                      Text(
                        [
                          'General', 'Philosophy', 'Religion', 'Soc. Sci.', 'Language',
                          'Science', 'Tech', 'Arts', 'Literature', 'History'
                        ][i],
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
              ],
            ),
            Expanded(
              child: BarChart(
                BarChartData(
                  maxY: maxCategoryCount.toDouble(),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final categories = [
                          'General Works', 'Philosophy', 'Religion', 'Social Sciences', 'Language',
                          'Science', 'Technology', 'Arts', 'Literature', 'History'
                        ];
                        return BarTooltipItem(
                          '${categories[group.x]}\n${rod.toY.toInt()}',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          int middleValue = (maxCategoryCount / 2).round();
                          if (value == 0 || value == middleValue || value == maxCategoryCount) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(categoryCounts.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: categoryCounts[i].toDouble(),
                          color: categoryColors[i],
                          width: 20,
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxCategoryCount.toDouble(),
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                      ],
                    );
                  }),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    horizontalInterval: maxCategoryCount / 2,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.white.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<List<int>> fetchThesisCategoryData() async {
    final counts = await Future.wait([
      firestoreService.getCountByClassificationRange('theses', '0.0', '99.99'),
      firestoreService.getCountByClassificationRange('theses', '100.0', '199.99'),
      firestoreService.getCountByClassificationRange('theses', '200.0', '299.99'),
      firestoreService.getCountByClassificationRange('theses', '300.0', '399.99'),
      firestoreService.getCountByClassificationRange('theses', '400.0', '499.99'),
      firestoreService.getCountByClassificationRange('theses', '500.0', '599.99'),
      firestoreService.getCountByClassificationRange('theses', '600.0', '699.99'),
      firestoreService.getCountByClassificationRange('theses', '700.0', '799.99'),
      firestoreService.getCountByClassificationRange('theses', '800.0', '899.99'),
      firestoreService.getCountByClassificationRange('theses', '900.0', '999.99'),
    ]);

    return counts.map((count) => count ?? 0).toList();
  }
}
