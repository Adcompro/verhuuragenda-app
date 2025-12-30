import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../core/api/api_client.dart';

class FinancialYearScreen extends StatefulWidget {
  const FinancialYearScreen({super.key});

  @override
  State<FinancialYearScreen> createState() => _FinancialYearScreenState();
}

class _FinancialYearScreenState extends State<FinancialYearScreen> {
  bool _isLoading = true;
  bool _isExporting = false;
  bool _isCopyingSeasons = false;
  String? _error;
  Map<String, dynamic> _stats = {};
  List<dynamic> _outstandingBookings = [];
  int _selectedYear = DateTime.now().year;
  int _sourceYear = DateTime.now().year;
  int _targetYear = DateTime.now().year + 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load statistics
      final statsResponse = await ApiClient.instance.get(
        ApiConfig.statistics,
        queryParameters: {'year': _selectedYear},
      );

      // Load bookings with outstanding payments
      final bookingsResponse = await ApiClient.instance.get(
        ApiConfig.bookings,
        queryParameters: {
          'year': _selectedYear,
          'payment_status': 'unpaid,partial',
          'per_page': 100,
        },
      );

      setState(() {
        _stats = statsResponse.data is Map ? Map<String, dynamic>.from(statsResponse.data) : {};
        _outstandingBookings = bookingsResponse.data['data'] is List
            ? List.from(bookingsResponse.data['data'])
            : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _exportReport() async {
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isExporting = true);

    try {
      // Build CSV content
      final buffer = StringBuffer();

      // Header
      buffer.writeln('VerhuurAgenda ${l10n.yearOverview} $_selectedYear');
      buffer.writeln('');

      // Summary section
      buffer.writeln('SAMENVATTING');
      final kpis = _stats['kpis'] ?? {};
      buffer.writeln('${l10n.totalRevenue},€${_formatNumber(kpis['total_revenue'] ?? 0)}');
      buffer.writeln('${l10n.totalBookings},${kpis['total_bookings'] ?? 0}');
      buffer.writeln('${l10n.occupancyRateLabel},${kpis['occupancy_rate'] ?? 0}%');
      buffer.writeln('${l10n.averageStay},${kpis['average_stay'] ?? 0} ${l10n.nights}');
      buffer.writeln('');

      // Outstanding payments
      if (_outstandingBookings.isNotEmpty) {
        buffer.writeln('${l10n.outstandingPayments}');
        buffer.writeln('ID,Gast,Accommodatie,Check-in,Totaal,Betaald,Openstaand');

        double totalOutstanding = 0;
        for (final booking in _outstandingBookings) {
          final remaining = (booking['remaining_amount'] ?? 0).toDouble();
          totalOutstanding += remaining;
          buffer.writeln(
            '${booking['id']},'
            '${booking['guest']?['full_name'] ?? '-'},'
            '${booking['accommodation']?['name'] ?? '-'},'
            '${booking['check_in'] ?? '-'},'
            '€${_formatNumber(booking['total_amount'] ?? 0)},'
            '€${_formatNumber(booking['paid_amount'] ?? 0)},'
            '€${_formatNumber(remaining)}'
          );
        }
        buffer.writeln('');
        buffer.writeln('${l10n.totalOutstanding},€${_formatNumber(totalOutstanding)}');
        buffer.writeln('');
      }

      // Revenue by month
      final revenueByMonth = _stats['revenue_by_month'] as List? ?? [];
      if (revenueByMonth.isNotEmpty) {
        buffer.writeln('OMZET PER MAAND');
        final months = [
          l10n.january, l10n.february, l10n.march, l10n.april,
          l10n.may, l10n.june, l10n.july, l10n.august,
          l10n.september, l10n.october, l10n.november, l10n.december
        ];
        for (final item in revenueByMonth) {
          final monthIndex = (item['month'] ?? 1) - 1;
          if (monthIndex >= 0 && monthIndex < 12) {
            buffer.writeln('${months[monthIndex]},€${_formatNumber(item['revenue'] ?? 0)}');
          }
        }
        buffer.writeln('');
      }

      // Save and share
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/jaarrapport_$_selectedYear.csv');
      await file.writeAsString(buffer.toString());

      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'VerhuurAgenda ${l10n.yearOverview} $_selectedYear',
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : const Rect.fromLTWH(0, 0, 100, 100),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.reportExported)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _copySeasons() async {
    final l10n = AppLocalizations.of(context)!;

    if (_sourceYear == _targetYear) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.seasonsAlreadyExist)),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.copySeasons),
        content: Text(
          l10n.copySeasonsConfirmation(_sourceYear, _targetYear),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCopyingSeasons = true);

    try {
      await ApiClient.instance.post(
        '${ApiConfig.seasons}/copy',
        data: {
          'from_year': _sourceYear,
          'to_year': _targetYear,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.seasonsCopied)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCopyingSeasons = false);
      }
    }
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    final number = value is num ? value : double.tryParse(value.toString()) ?? 0;
    return number.toStringAsFixed(2).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.financialYear),
        actions: [
          PopupMenuButton<int>(
            onSelected: (year) {
              setState(() => _selectedYear = year);
              _loadData();
            },
            itemBuilder: (context) {
              final currentYear = DateTime.now().year;
              return List.generate(6, (index) {
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
          : _error != null
              ? _buildError(l10n)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Year Overview section
                        _buildSectionHeader(l10n.yearOverview),
                        const SizedBox(height: 12),
                        _buildKpiGrid(l10n),
                        const SizedBox(height: 24),

                        // Outstanding Payments section
                        _buildSectionHeader(l10n.outstandingPayments),
                        const SizedBox(height: 12),
                        _buildOutstandingCard(l10n),
                        const SizedBox(height: 24),

                        // Export button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isExporting ? null : _exportReport,
                            icon: _isExporting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.download),
                            label: Text(l10n.exportYearReport),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Copy Seasons section
                        _buildSectionHeader(l10n.copySeasonsToYear),
                        const SizedBox(height: 4),
                        Text(
                          l10n.copySeasonsDescription,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildCopySeasonsCard(l10n),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildError(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(l10n.somethingWentWrong),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadData,
            child: Text(l10n.tryAgain),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey[500],
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildKpiGrid(AppLocalizations l10n) {
    final kpis = _stats['kpis'] ?? {};

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildKpiCard(
          l10n.totalRevenue,
          '€${_formatNumber(kpis['total_revenue'] ?? 0)}',
          Icons.euro,
          Colors.green,
        ),
        _buildKpiCard(
          l10n.totalBookings,
          '${kpis['total_bookings'] ?? 0}',
          Icons.book_online,
          Colors.blue,
        ),
        _buildKpiCard(
          l10n.occupancyRateLabel,
          '${kpis['occupancy_rate'] ?? 0}%',
          Icons.pie_chart,
          Colors.orange,
        ),
        _buildKpiCard(
          l10n.averageStay,
          '${kpis['average_stay'] ?? 0} ${l10n.nights}',
          Icons.nights_stay,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
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
    );
  }

  Widget _buildOutstandingCard(AppLocalizations l10n) {
    double totalOutstanding = 0;
    for (final booking in _outstandingBookings) {
      totalOutstanding += (booking['remaining_amount'] ?? 0).toDouble();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _outstandingBookings.isEmpty ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _outstandingBookings.isEmpty ? Colors.green[200]! : Colors.orange[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _outstandingBookings.isEmpty ? Icons.check_circle : Icons.warning,
                color: _outstandingBookings.isEmpty ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.bookingsWithOutstanding(_outstandingBookings.length),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          if (_outstandingBookings.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${l10n.totalOutstanding}: €${_formatNumber(totalOutstanding)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCopySeasonsCard(AppLocalizations l10n) {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (i) => currentYear - 1 + i);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectSourceYear,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    DropdownButton<int>(
                      value: _sourceYear,
                      isExpanded: true,
                      onChanged: (value) {
                        if (value != null) setState(() => _sourceYear = value);
                      },
                      items: years.map((year) {
                        return DropdownMenuItem(
                          value: year,
                          child: Text('$year'),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.arrow_forward, color: Colors.grey),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectTargetYear,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    DropdownButton<int>(
                      value: _targetYear,
                      isExpanded: true,
                      onChanged: (value) {
                        if (value != null) setState(() => _targetYear = value);
                      },
                      items: years.map((year) {
                        return DropdownMenuItem(
                          value: year,
                          child: Text('$year'),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isCopyingSeasons ? null : _copySeasons,
              icon: _isCopyingSeasons
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.copy),
              label: Text(l10n.copySeasons),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
