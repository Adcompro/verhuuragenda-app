import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../core/api/api_client.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _stats = {};
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiClient.instance.get(
        ApiConfig.statistics,
        queryParameters: {'year': _selectedYear},
      );

      setState(() {
        _stats = response.data is Map ? Map<String, dynamic>.from(response.data) : {};
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Kon statistieken niet laden';
        _isLoading = false;
        // Use demo data for now
        _stats = _getDemoData();
      });
    }
  }

  Map<String, dynamic> _getDemoData() {
    return {
      'kpis': {
        'total_revenue': 45680.00,
        'total_bookings': 87,
        'average_stay': 5.2,
        'occupancy_rate': 72.5,
        'revenue_change': 12.5,
        'bookings_change': 8.3,
      },
      'revenue_by_month': [
        {'month': 1, 'revenue': 2450.0},
        {'month': 2, 'revenue': 1890.0},
        {'month': 3, 'revenue': 3200.0},
        {'month': 4, 'revenue': 4100.0},
        {'month': 5, 'revenue': 5600.0},
        {'month': 6, 'revenue': 6800.0},
        {'month': 7, 'revenue': 8200.0},
        {'month': 8, 'revenue': 7900.0},
        {'month': 9, 'revenue': 4200.0},
        {'month': 10, 'revenue': 3100.0},
        {'month': 11, 'revenue': 2800.0},
        {'month': 12, 'revenue': 3440.0},
      ],
      'occupancy_by_month': [
        {'month': 1, 'rate': 45.0},
        {'month': 2, 'rate': 38.0},
        {'month': 3, 'rate': 52.0},
        {'month': 4, 'rate': 65.0},
        {'month': 5, 'rate': 78.0},
        {'month': 6, 'rate': 92.0},
        {'month': 7, 'rate': 98.0},
        {'month': 8, 'rate': 95.0},
        {'month': 9, 'rate': 72.0},
        {'month': 10, 'rate': 58.0},
        {'month': 11, 'rate': 48.0},
        {'month': 12, 'rate': 55.0},
      ],
      'bookings_by_source': [
        {'source': 'Direct', 'count': 35, 'percentage': 40.2},
        {'source': 'Airbnb', 'count': 28, 'percentage': 32.2},
        {'source': 'Booking.com', 'count': 18, 'percentage': 20.7},
        {'source': 'Anders', 'count': 6, 'percentage': 6.9},
      ],
      'top_accommodations': [
        {'name': 'Villa Zeezicht', 'revenue': 18500.0, 'bookings': 32},
        {'name': 'Appartement Haven', 'revenue': 12300.0, 'bookings': 28},
        {'name': 'Huisje Duinen', 'revenue': 9800.0, 'bookings': 18},
        {'name': 'Studio Centrum', 'revenue': 5080.0, 'bookings': 9},
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistieken'),
        actions: [
          // Year selector
          PopupMenuButton<int>(
            onSelected: (year) {
              setState(() => _selectedYear = year);
              _loadStatistics();
            },
            itemBuilder: (context) {
              final currentYear = DateTime.now().year;
              return List.generate(5, (index) {
                final year = currentYear - index;
                return PopupMenuItem(
                  value: year,
                  child: Text('$year'),
                );
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '$_selectedYear',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KPI Cards
                    _buildKPICards(),
                    const SizedBox(height: 24),

                    // Revenue chart
                    _buildSectionTitle('Omzet per maand'),
                    _buildRevenueChart(),
                    const SizedBox(height: 24),

                    // Occupancy chart
                    _buildSectionTitle('Bezettingsgraad'),
                    _buildOccupancyChart(),
                    const SizedBox(height: 24),

                    // Bookings by source
                    _buildSectionTitle('Boekingen per bron'),
                    _buildSourceChart(),
                    const SizedBox(height: 24),

                    // Top accommodations
                    _buildSectionTitle('Top accommodaties'),
                    _buildTopAccommodations(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildKPICards() {
    final kpis = _stats['kpis'] as Map<String, dynamic>? ?? {};

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildKPICard(
          'Totale Omzet',
          _formatCurrency(kpis['total_revenue'] ?? 0),
          Icons.euro,
          AppTheme.primaryColor,
          change: kpis['revenue_change'],
        ),
        _buildKPICard(
          'Boekingen',
          '${kpis['total_bookings'] ?? 0}',
          Icons.calendar_today,
          Colors.blue,
          change: kpis['bookings_change'],
        ),
        _buildKPICard(
          'Gem. Verblijf',
          '${(kpis['average_stay'] ?? 0).toStringAsFixed(1)} nachten',
          Icons.nights_stay,
          Colors.purple,
        ),
        _buildKPICard(
          'Bezetting',
          '${(kpis['occupancy_rate'] ?? 0).toStringAsFixed(1)}%',
          Icons.home,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color, {double? change}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (change != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: change >= 0 ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          change >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 12,
                          color: change >= 0 ? Colors.green : Colors.red,
                        ),
                        Text(
                          '${change.abs().toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: change >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    final revenueData = (_stats['revenue_by_month'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        [];

    if (revenueData.isEmpty) {
      return _buildEmptyChart('Geen omzetgegevens beschikbaar');
    }

    final maxRevenue = revenueData
        .map((e) => (e['revenue'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxRevenue * 1.2,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      _formatCurrency(rod.toY),
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
                      const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                      if (value.toInt() >= 0 && value.toInt() < 12) {
                        return Text(
                          months[value.toInt()],
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        _formatCompactCurrency(value),
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxRevenue / 4,
                getDrawingHorizontalLine: (value) {
                  return FlLine(color: Colors.grey[200]!, strokeWidth: 1);
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(12, (index) {
                final monthData = revenueData.firstWhere(
                  (e) => e['month'] == index + 1,
                  orElse: () => {'month': index + 1, 'revenue': 0.0},
                );
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: (monthData['revenue'] as num).toDouble(),
                      color: AppTheme.primaryColor,
                      width: 16,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOccupancyChart() {
    final occupancyData = (_stats['occupancy_by_month'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        [];

    if (occupancyData.isEmpty) {
      return _buildEmptyChart('Geen bezettingsgegevens beschikbaar');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: 100,
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      return LineTooltipItem(
                        '${spot.y.toStringAsFixed(0)}%',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    }).toList();
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                      if (value.toInt() >= 0 && value.toInt() < 12) {
                        return Text(
                          months[value.toInt()],
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 35,
                    interval: 25,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}%',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 25,
                getDrawingHorizontalLine: (value) {
                  return FlLine(color: Colors.grey[200]!, strokeWidth: 1);
                },
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(12, (index) {
                    final monthData = occupancyData.firstWhere(
                      (e) => e['month'] == index + 1,
                      orElse: () => {'month': index + 1, 'rate': 0.0},
                    );
                    return FlSpot(index.toDouble(), (monthData['rate'] as num).toDouble());
                  }),
                  isCurved: true,
                  color: Colors.orange,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: Colors.orange,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.orange.withOpacity(0.15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceChart() {
    final sourceData = (_stats['bookings_by_source'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        [];

    if (sourceData.isEmpty) {
      return _buildEmptyChart('Geen brongegevens beschikbaar');
    }

    final colors = [
      AppTheme.primaryColor,
      Colors.pink,
      Colors.blue,
      Colors.grey,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Pie chart
            SizedBox(
              width: 140,
              height: 140,
              child: PieChart(
                PieChartData(
                  sections: List.generate(sourceData.length, (index) {
                    final item = sourceData[index];
                    return PieChartSectionData(
                      value: (item['percentage'] as num).toDouble(),
                      color: colors[index % colors.length],
                      radius: 50,
                      title: '${(item['percentage'] as num).toStringAsFixed(0)}%',
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }),
                  sectionsSpace: 2,
                  centerSpaceRadius: 20,
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Legend
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(sourceData.length, (index) {
                  final item = sourceData[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colors[index % colors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item['source'] as String,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          '${item['count']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAccommodations() {
    final topAccommodations = (_stats['top_accommodations'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        [];

    if (topAccommodations.isEmpty) {
      return _buildEmptyChart('Geen accommodatiegegevens beschikbaar');
    }

    final maxRevenue = topAccommodations
        .map((e) => (e['revenue'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(topAccommodations.length, (index) {
            final item = topAccommodations[index];
            final revenue = (item['revenue'] as num).toDouble();
            final progress = revenue / maxRevenue;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _getMedalColor(index),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item['name'] as String,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatCurrency(revenue),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${item['bookings']} boekingen',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(_getMedalColor(index)),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildEmptyChart(String message) {
    return Card(
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            message,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      ),
    );
  }

  Color _getMedalColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber[600]!;
      case 1:
        return Colors.grey[500]!;
      case 2:
        return Colors.brown[400]!;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _formatCurrency(double amount) {
    return '\u20AC ${amount.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatCompactCurrency(double amount) {
    if (amount >= 1000) {
      return '\u20AC${(amount / 1000).toStringAsFixed(0)}k';
    }
    return '\u20AC${amount.toStringAsFixed(0)}';
  }
}
