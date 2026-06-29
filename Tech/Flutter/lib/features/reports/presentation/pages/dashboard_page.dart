import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/constants/app_colors.dart';
import 'package:flutter_pos/core/constants/app_sizes.dart';
import 'package:flutter_pos/core/constants/app_strings.dart';
import 'package:flutter_pos/core/utils/currency_formatter.dart';
import 'package:flutter_pos/core/utils/date_formatter.dart';
import 'package:flutter_pos/features/reports/presentation/cubit/dashboard_cubit.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.dashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<DashboardCubit>().loadDashboard(),
          ),
        ],
      ),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state.status == DashboardStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () => context.read<DashboardCubit>().loadDashboard(),
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.md),
              children: [
                _buildDateHeader(context),
                const SizedBox(height: AppSizes.md),
                _buildSummaryCards(state),
                const SizedBox(height: AppSizes.md),
                _buildSalesChart(context, state),
                const SizedBox(height: AppSizes.md),
                _buildTopProducts(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context) {
    return Text(
      DateFormatter.formatFullDate(DateTime.now()),
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
    );
  }

  Widget _buildSummaryCards(DashboardState state) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSizes.sm,
      mainAxisSpacing: AppSizes.sm,
      childAspectRatio: 1.5,
      children: [
        _SummaryCard(
          title: AppStrings.totalSales,
          value: CurrencyFormatter.formatCompact(state.totalSales),
          icon: Icons.trending_up,
          color: AppColors.success,
        ),
        _SummaryCard(
          title: AppStrings.totalTransactions,
          value: '${state.totalTransactions}',
          icon: Icons.receipt_long,
          color: AppColors.primary,
        ),
        _SummaryCard(
          title: 'Produk Terjual',
          value: '${state.totalItems} item',
          icon: Icons.shopping_bag,
          color: AppColors.accent,
        ),
        _SummaryCard(
          title: 'Rata-rata',
          value: CurrencyFormatter.formatCompact(state.averageTransaction),
          icon: Icons.analytics,
          color: AppColors.secondary,
        ),
      ],
    );
  }

  Widget _buildSalesChart(BuildContext context, DashboardState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Penjualan 7 Hari Terakhir',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSizes.md),
            SizedBox(
              height: 200,
              child: state.weeklyData.isEmpty
                  ? const Center(
                      child: Text('Belum ada data',
                          style: TextStyle(color: AppColors.textHint)),
                    )
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _getMaxY(state.weeklyData),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIdx, rod, rodIdx) {
                              return BarTooltipItem(
                                CurrencyFormatter.formatCompact(rod.toY),
                                const TextStyle(
                                    color: Colors.white, fontSize: 12),
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
                                if (value.toInt() >= state.weeklyData.length) {
                                  return const SizedBox.shrink();
                                }
                                final date =
                                    state.weeklyData[value.toInt()].date;
                                return Text(
                                  DateFormat('E', 'id').format(date),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                        barGroups: state.weeklyData.asMap().entries.map((e) {
                          return BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                toY: e.value.totalSales,
                                color: AppColors.primary,
                                width: 20,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  double _getMaxY(List<DaySales> data) {
    if (data.isEmpty) return 100;
    final max = data.map((d) => d.totalSales).reduce((a, b) => a > b ? a : b);
    return max == 0 ? 100 : max * 1.2;
  }

  Widget _buildTopProducts(BuildContext context, DashboardState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.bestSelling,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSizes.sm),
            if (state.bestSellingProducts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSizes.lg),
                child: Center(
                  child: Text('Belum ada data',
                      style: TextStyle(color: AppColors.textHint)),
                ),
              )
            else
              ...state.bestSellingProducts
                  .take(5)
                  .toList()
                  .asMap()
                  .entries
                  .map((e) {
                final item = e.value;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      '${e.key + 1}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Text(
                    item['product_name'] as String,
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    '${item['quantity']} terjual',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Text(
                    CurrencyFormatter.formatCompact(
                        (item['total'] as num).toDouble()),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: AppSizes.fontXl,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSm,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
