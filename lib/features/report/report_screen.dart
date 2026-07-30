import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/status_dialog.dart';
import '../../data/dummy/dummy_data.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final DummyData _data = DummyData();
  int _reportTabIndex = 0; // 0: Penjualan, 1: Pembelian
  int _periodIndex = 0; // 0: Hari Ini, 1: Bulan Ini, 2: Tahun Ini, 3: Selama...

  final _periods = ['Hari Ini', 'Bulan Ini', 'Tahun Ini', 'Selama...'];

  // Dummy report data based on period and tab
  Map<String, dynamic> get _reportData {
    if (_reportTabIndex == 0) {
      // Penjualan
      switch (_periodIndex) {
        case 0: return {'total': 0, 'bars': <Map<String, dynamic>>[]};
        case 1: return {
          'total': 7350000,
          'bars': [
            {'label': '13', 'value': 4200000},
            {'label': '5', 'value': 2600000},
          ],
        };
        case 2: return {
          'total': 8450000,
          'bars': [
            {'label': 'Jun', 'value': 7200000},
            {'label': 'Mei', 'value': 850000},
          ],
        };
        default: return {
          'total': 8450000,
          'bars': [
            {'label': 'Jun', 'value': 7200000},
            {'label': 'Mei', 'value': 850000},
          ],
        };
      }
    } else {
      // Pembelian
      switch (_periodIndex) {
        case 0: return {'total': 0, 'bars': <Map<String, dynamic>>[]};
        case 1: return {
          'total': 7350000,
          'bars': [
            {'label': '13', 'value': 4500000},
            {'label': '5', 'value': 2850000},
          ],
        };
        case 2: return {
          'total': 8450000,
          'bars': [
            {'label': 'Jun', 'value': 7350000},
            {'label': 'Mei', 'value': 1100000},
          ],
        };
        default: return {
          'total': 8450000,
          'bars': [
            {'label': 'Jun', 'value': 7350000},
            {'label': 'Mei', 'value': 1100000},
          ],
        };
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _reportData;
    final total = report['total'] as int;
    final bars = report['bars'] as List<Map<String, dynamic>>;
    final maxBarValue = bars.isEmpty
        ? 1.0
        : bars.map((b) => (b['value'] as int).toDouble()).reduce((a, b) => a > b ? a : b);
    final reportTypeLabel = _reportTabIndex == 0 ? 'Penjualan' : 'Pengeluaran';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: AppColors.primary),
            tooltip: 'Export CSV',
            onPressed: () {
              final count = _data.transactions.length;
              showStatusSnackBar(
                context,
                message: 'Laporan berhasil diekspor ke CSV ($count transaksi)',
                isSuccess: true,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Report type toggle
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _tabButton('Laporan Penjualan', 0),
                        _tabButton('Laporan Pembelian', 1),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Period chips
                  SizedBox(
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
                  ),
                  const SizedBox(height: 16),

                  // Total card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total $reportTypeLabel',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rp ${DummyData.formatCurrency(total)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Chart card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reportTypeLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (bars.isEmpty)
                          const SizedBox(
                            height: 160,
                            child: Center(
                              child: Text(
                                'Belum ada data',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            height: 200,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Y-axis labels
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('${(maxBarValue / 1000).toInt()}k',
                                        style: _axisStyle),
                                    Text('${(maxBarValue * 0.75 / 1000).toInt()}k',
                                        style: _axisStyle),
                                    Text('${(maxBarValue * 0.5 / 1000).toInt()}k',
                                        style: _axisStyle),
                                    Text('${(maxBarValue * 0.25 / 1000).toInt()}k',
                                        style: _axisStyle),
                                    Text('0k', style: _axisStyle),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                // Bars
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: bars.map((bar) {
                                      final value = (bar['value'] as int).toDouble();
                                      final height = (value / maxBarValue) * 170;
                                      return Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Container(
                                            width: 60,
                                            height: height.clamp(4, 170),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                      top: Radius.circular(4)),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            bar['label'] as String,
                                            style: _axisStyle,
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _axisStyle => const TextStyle(
        fontSize: 11,
        color: AppColors.textSecondary,
      );

  Widget _tabButton(String label, int index) {
    final isSelected = _reportTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _reportTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
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
      ),
    );
  }
}
