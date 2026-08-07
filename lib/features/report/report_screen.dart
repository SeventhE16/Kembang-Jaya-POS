import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/app_empty_state.dart';
import 'package:provider/provider.dart';
import '../../data/models/transaction_model.dart';
import '../../data/providers/transaction_provider.dart';
import '../../data/providers/mutation_provider.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int _reportTabIndex = 0; // 0: Penjualan, 1: Pembelian
  int _periodIndex = 1; // 0: Hari Ini, 1: Bulan Ini, 2: Tahun Ini, 3: Semua

  final _periods = ['Hari Ini', 'Bulan Ini', 'Tahun Ini', 'Semua'];
  final _currencyFormat = NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0);

  // --- Data filtering helpers ---

  DateTime get _periodStart {
    final now = DateTime.now();
    switch (_periodIndex) {
      case 0: return DateTime(now.year, now.month, now.day);
      case 1: return DateTime(now.year, now.month, 1);
      case 2: return DateTime(now.year, 1, 1);
      default: return DateTime(2000);
    }
  }

  List<Transaction> _filteredTransactions(TransactionProvider provider, {String? type}) {
    final start = _periodStart;
    return provider.transactions.where((t) {
      if (t.date.isBefore(start)) return false;
      if (type != null && t.type != type) return false;
      return true;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<StockEntry> _filteredStockEntries(TransactionProvider provider) {
    final start = _periodStart;
    return provider.stockEntries.where((e) => !e.date.isBefore(start)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<InstallmentPayment> _filteredInstallments(TransactionProvider provider, {String type = 'sale'}) {
    final start = _periodStart;
    return provider.allInstallments.where((i) {
      if (i.date.isBefore(start)) return false;
      // Filter by transaction type
      final tx = provider.transactions.where((t) => t.id == i.transactionId).firstOrNull;
      if (tx != null && tx.type != type) return false;
      return true;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Get transactions matching a specific period label
  List<Transaction> _transactionsForLabel(List<Transaction> allFiltered, String label) {
    return allFiltered.where((t) => _labelForDate(t.date) == label).toList();
  }

  void _navigateToDetail(List<Transaction> transactions, String label) {
    Navigator.pushNamed(context, '/report_detail', arguments: {
      'transactions': transactions,
      'title': label,
      'periodLabel': _periods[_periodIndex],
    });
  }

  // --- Aggregation ---

  /// Groups transactions by a label key and returns list of { label, totalPendapatan, totalKeuntungan, count }
  List<Map<String, dynamic>> _aggregateTransactions(List<Transaction> txns) {
    if (txns.isEmpty) return [];

    final Map<String, Map<String, dynamic>> grouped = {};

    for (var t in txns) {
      final key = _labelForDate(t.date);
      grouped.putIfAbsent(key, () => {'label': key, 'pendapatan': 0.0, 'keuntungan': 0.0, 'count': 0, 'sortDate': t.date});
      grouped[key]!['pendapatan'] = (grouped[key]!['pendapatan'] as double) + t.total;
      // Keuntungan = total - subtotal cost (approximation: total - sum of base prices)
      double costBasis = 0;
      for (var item in t.items) {
        costBasis += item.product.basePrice * item.quantity;
      }
      grouped[key]!['keuntungan'] = (grouped[key]!['keuntungan'] as double) + (t.total - costBasis);
      grouped[key]!['count'] = (grouped[key]!['count'] as int) + 1;
    }

    final result = grouped.values.toList();
    result.sort((a, b) => (a['sortDate'] as DateTime).compareTo(b['sortDate'] as DateTime));
    return result;
  }

  List<Map<String, dynamic>> _aggregateStockEntries(List<StockEntry> entries) {
    if (entries.isEmpty) return [];

    final Map<String, Map<String, dynamic>> grouped = {};

    for (var e in entries) {
      final key = _labelForDate(e.date);
      grouped.putIfAbsent(key, () => {'label': key, 'pengeluaran': 0.0, 'count': 0, 'sortDate': e.date});
      grouped[key]!['pengeluaran'] = (grouped[key]!['pengeluaran'] as double) + e.totalCost;
      grouped[key]!['count'] = (grouped[key]!['count'] as int) + 1;
    }

    final result = grouped.values.toList();
    result.sort((a, b) => (a['sortDate'] as DateTime).compareTo(b['sortDate'] as DateTime));
    return result;
  }

  List<Map<String, dynamic>> _aggregateInstallments(List<InstallmentPayment> insts) {
    if (insts.isEmpty) return [];

    final Map<String, Map<String, dynamic>> grouped = {};

    for (var i in insts) {
      final key = _labelForDate(i.date);
      grouped.putIfAbsent(key, () => {'label': key, 'uang_masuk': 0.0, 'count': 0, 'sortDate': i.date, 'items': <InstallmentPayment>[]});
      grouped[key]!['uang_masuk'] = (grouped[key]!['uang_masuk'] as double) + i.amount;
      grouped[key]!['count'] = (grouped[key]!['count'] as int) + 1;
      (grouped[key]!['items'] as List<InstallmentPayment>).add(i);
    }

    final result = grouped.values.toList();
    result.sort((a, b) => (a['sortDate'] as DateTime).compareTo(b['sortDate'] as DateTime));
    return result;
  }

  String _labelForDate(DateTime date) {
    switch (_periodIndex) {
      case 0: // Hari Ini — group by hour
        return '${date.hour.toString().padLeft(2, '0')}:00';
      case 1: // Bulan Ini — group by day
        return date.day.toString();
      case 2: // Tahun Ini — group by month name
        return DateFormat.MMM('id').format(date);
      default: // Semua — group by month-year
        return DateFormat('MMM yy', 'id').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/report'),
      appBar: AppBar(
        title: const Text(
          'Laporan',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, size: 26),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          return Column(
            children: [
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Report type toggle
                      _buildTabToggle(),
                      const SizedBox(height: 16),

                      // Period chips
                      _buildPeriodChips(),
                      const SizedBox(height: 16),

                      // Content based on tab
                      if (_reportTabIndex == 0)
                        _buildSalesReport(provider)
                      else if (_reportTabIndex == 1)
                        _buildPurchaseReport(provider)
                      else if (_reportTabIndex == 2)
                        _buildStockOpnameReport(provider)
                      else if (_reportTabIndex == 3)
                        _buildGradeMutationReport()
                      else if (_reportTabIndex == 4)
                        _buildCicilanReport(provider)
                      else if (_reportTabIndex == 5)
                        _buildCicilanKeluarReport(provider),
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

  // ========================================
  // ADDITIONAL REPORTS
  // ========================================

  Widget _buildPlaceholder(String title) {
    return AppEmptyState(
      icon: Icons.construction,
      title: 'Laporan $title',
      subtitle: 'Fitur ini sedang dalam pengembangan.',
    );
  }

  Widget _buildStockOpnameReport(TransactionProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final opnames = provider.stockOpnames;
    
    if (opnames.isEmpty) {
      return const AppEmptyState(
        icon: Icons.inventory,
        title: 'Belum ada Stok Opname',
        subtitle: 'Riwayat stok opname akan muncul di sini.',
      );
    }

    // Filter by period
    final now = DateTime.now();
    DateTime startDate;
    switch (_periodIndex) {
      case 0: // Hari ini
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 1: // 7 Hari
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 2: // 30 Hari
        startDate = now.subtract(const Duration(days: 30));
        break;
      case 3: // Semua
      default:
        startDate = DateTime(2000);
        break;
    }

    final filtered = opnames.where((o) => o.date.isAfter(startDate) || o.date.isAtSameMomentAs(startDate)).toList();
    filtered.sort((a, b) => b.date.compareTo(a.date));

    if (filtered.isEmpty) {
      return const AppEmptyState(
        icon: Icons.search_off,
        title: 'Tidak ada data',
        subtitle: 'Tidak ada stok opname pada periode ini.',
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final opname = filtered[index];
        return InkWell(
          onTap: () {
            Navigator.pushNamed(context, '/report_stock_opname_detail', arguments: opname);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('dd MMM yyyy, HH:mm', 'id').format(opname.date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Oleh: ${opname.cashierName}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text('${opname.totalItemsChanged} Barang', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGradeMutationReport() {
    return Consumer<MutationProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final mutations = provider.mutations;
        
        if (mutations.isEmpty) {
          return const AppEmptyState(
            icon: Icons.history,
            title: 'Belum ada mutasi',
            subtitle: 'Riwayat mutasi grade barang akan muncul di sini.',
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: mutations.length,
          itemBuilder: (context, index) {
            final mut = mutations[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('dd MMM yyyy, HH:mm', 'id').format(mut.date), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Text(mut.createdBy ?? 'Staff', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Asal', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            Text(mut.sourceProductName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primary),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tujuan', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            Text(mut.targetProductName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text('Jumlah: ${mut.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ========================================
  // SALES REPORT (Laporan Penjualan)
  // ========================================
  Widget _buildSalesReport(TransactionProvider provider) {
    final transactions = _filteredTransactions(provider, type: 'sale');
    final aggregated = _aggregateTransactions(transactions);

    final totalPendapatan = transactions.fold<double>(0, (sum, t) => sum + t.total);
    final totalTransaksi = transactions.length;

    return Column(
      children: [
        // Summary bar
        _buildSummaryBar(
          jumlahTransaksi: totalTransaksi,
          pendapatan: totalPendapatan,
          keuntungan: 0, // Ignored now
        ),
        const SizedBox(height: 16),

        // Chart
        if (aggregated.isNotEmpty)
          _buildLineChart(
            aggregated: aggregated,
            valueKey: 'pendapatan',
            chartTitle: 'Pendapatan',
          ),

        if (aggregated.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: AppEmptyState(
              icon: Icons.bar_chart_rounded,
              title: 'Belum ada transaksi',
              subtitle: 'Data penjualan akan muncul setelah ada transaksi.',
            ),
          ),

        const SizedBox(height: 16),

        // List per period
        ...aggregated.reversed.map((item) => _buildSalesListItem(item, _filteredTransactions(provider))),
      ],
    );
  }

  // ========================================
  // PURCHASE REPORT (Laporan Pembelian)
  // ========================================
  Widget _buildPurchaseReport(TransactionProvider provider) {
    final transactions = _filteredTransactions(provider, type: 'purchase');
    final aggregated = _aggregateTransactions(transactions);

    final totalPengeluaran = transactions.fold<double>(0, (sum, t) => sum + t.total);
    final totalTransaksi = transactions.length;

    return Column(
      children: [
        // Summary bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _summaryItem('Jml Pembelian', totalTransaksi.toString()),
              ),
              Container(width: 1, height: 36, color: Colors.white24),
              Expanded(
                child: _summaryItem('Total Pengeluaran', 'Rp ${_currencyFormat.format(totalPengeluaran)}'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Chart
        if (aggregated.isNotEmpty)
          _buildLineChart(
            aggregated: aggregated,
            valueKey: 'pendapatan', // Using the same key from _aggregateTransactions
            chartTitle: 'Pengeluaran',
          ),

        if (aggregated.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: AppEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Belum ada pembelian',
              subtitle: 'Data pembelian akan muncul setelah ada transaksi pembelian stok.',
            ),
          ),

        const SizedBox(height: 16),

        // List per period
        ...aggregated.reversed.map((item) => _buildPurchaseListItem(item, transactions)),
      ],
    );
  }

  // ========================================
  // SHARED WIDGETS
  // ========================================

  Widget _buildTabToggle() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _tabButton('Penjualan', 0),
            _tabButton('Pembelian', 1),
            _tabButton('Stok Opname', 2),
            _tabButton('Mutasi Grade', 3),
            _tabButton('Cicilan Masuk', 4),
            _tabButton('Cicilan Keluar', 5),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChips() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _periods.length,
        itemBuilder: (context, index) {
          final isSelected = index == _periodIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                _periods[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => setState(() => _periodIndex = index),
              backgroundColor: AppColors.chipInactive,
              selectedColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              side: BorderSide.none,
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryBar({
    required int jumlahTransaksi,
    required double pendapatan,
    required double keuntungan,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _summaryItem('Jml Transaksi', jumlahTransaksi.toString())),
          Container(width: 1, height: 36, color: Colors.white24),
          Expanded(child: _summaryItem('Pendapatan', 'Rp ${_currencyFormat.format(pendapatan)}')),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildLineChart({
    required List<Map<String, dynamic>> aggregated,
    required String valueKey,
    required String chartTitle,
  }) {
    final spots = <FlSpot>[];
    final labels = <String>[];
    double maxY = 0;

    for (int i = 0; i < aggregated.length; i++) {
      final val = (aggregated[i][valueKey] as double);
      spots.add(FlSpot(i.toDouble(), val));
      labels.add(aggregated[i]['label'] as String);
      if (val > maxY) maxY = val;
    }

    // If maxY is 0, set a default to avoid rendering issues
    if (maxY == 0) maxY = 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 16),
            child: Text(chartTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.divider,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatChartValue(value),
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                        // Show fewer labels if too many data points
                        if (labels.length > 12 && idx % 2 != 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[idx],
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (spots.length - 1).toDouble().clamp(0, double.infinity),
                minY: 0,
                maxY: maxY * 1.15,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, xPercentage, bar, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: AppColors.primary,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.35),
                          AppColors.primary.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          'Rp ${_currencyFormat.format(spot.y)}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatChartValue(double value) {
    if (value >= 1000000000) return '${(value / 1000000000).toStringAsFixed(1)}M';
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}jt';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}rb';
    return value.toStringAsFixed(0);
  }

  Widget _buildSalesListItem(Map<String, dynamic> item, List<Transaction> allFiltered) {
    final label = item['label'] as String;
    final count = item['count'] as int;
    final pendapatan = item['pendapatan'] as double;

    return InkWell(
      onTap: () {
        final txns = _transactionsForLabel(allFiltered, label);
        _navigateToDetail(txns, label);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count transaksi',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pendapatan', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  Text(
                    'Rp ${_currencyFormat.format(pendapatan)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseListItem(Map<String, dynamic> item, List<Transaction> allFiltered) {
    final label = item['label'] as String;
    final count = item['count'] as int;
    final pengeluaran = item['pendapatan'] as double; // from aggregateTransactions

    return InkWell(
      onTap: () {
        final txns = _transactionsForLabel(allFiltered, label);
        _navigateToDetail(txns, label);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count suplai',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Pengeluaran', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  Text(
                    'Rp ${_currencyFormat.format(pengeluaran)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.error),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }



  // ========================================
  // CICILAN REPORT (Laporan Cicilan Piutang)
  // ========================================
  Widget _buildCicilanReport(TransactionProvider provider) {
    final installments = _filteredInstallments(provider);
    final aggregated = _aggregateInstallments(installments);

    final totalUangMasuk = installments.fold<double>(0, (sum, i) => sum + i.amount);
    final totalCount = installments.length;

    return Column(
      children: [
        // Summary bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text('Total Pembayaran', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      '$totalCount kali',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(
                child: Column(
                  children: [
                    const Text('Total Uang Masuk', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${_currencyFormat.format(totalUangMasuk)}',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (aggregated.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: AppEmptyState(
              icon: Icons.payments_outlined,
              title: 'Belum ada cicilan masuk',
              subtitle: 'Data cicilan piutang akan muncul di sini.',
            ),
          ),

        const SizedBox(height: 16),

        // List per period
        ...aggregated.reversed.map((item) {
          final label = item['label'] as String;
          final count = item['count'] as int;
          final uangMasuk = item['uang_masuk'] as double;
          final items = item['items'] as List<InstallmentPayment>;

          return InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/installment_detail', arguments: {
                'title': 'Cicilan Masuk - $label',
                'installments': items,
                'isOutgoing': false,
              });
            },
            child: Container(
            margin: const EdgeInsets.only(bottom: 1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label.toUpperCase(),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$count kali angsuran',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Uang Masuk (Cash In)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      Text(
                        'Rp ${_currencyFormat.format(uangMasuk)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.success),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
        );
      }),
      ],
    );
  }

  // ========================================
  // CICILAN KELUAR REPORT (Laporan Cicilan Hutang Supplier)
  // ========================================
  Widget _buildCicilanKeluarReport(TransactionProvider provider) {
    final installments = _filteredInstallments(provider, type: 'purchase');
    final aggregated = _aggregateInstallments(installments);

    final totalUangKeluar = installments.fold<double>(0, (sum, i) => sum + i.amount);
    final totalCount = installments.length;

    return Column(
      children: [
        // Summary bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text('Total Pembayaran', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      '$totalCount kali',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(
                child: Column(
                  children: [
                    const Text('Total Uang Keluar', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${_currencyFormat.format(totalUangKeluar)}',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (aggregated.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: AppEmptyState(
              icon: Icons.payments_outlined,
              title: 'Belum ada cicilan keluar',
              subtitle: 'Data cicilan hutang akan muncul di sini.',
            ),
          ),

        const SizedBox(height: 16),

        // List per period
        ...aggregated.reversed.map((item) {
          final label = item['label'] as String;
          final count = item['count'] as int;
          final uangKeluar = item['uang_masuk'] as double; // reused the key from aggregation
          final items = item['items'] as List<InstallmentPayment>;

          return InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/installment_detail', arguments: {
                'title': 'Cicilan Keluar - $label',
                'installments': items,
                'isOutgoing': true,
              });
            },
            child: Container(
            margin: const EdgeInsets.only(bottom: 1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label.toUpperCase(),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$count kali angsuran',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Uang Keluar (Cash Out)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      Text(
                        'Rp ${_currencyFormat.format(uangKeluar)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.error),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
        );
      }),
      ],
    );
  }

  Widget _tabButton(String label, int index) {
    final isSelected = _reportTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _reportTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
