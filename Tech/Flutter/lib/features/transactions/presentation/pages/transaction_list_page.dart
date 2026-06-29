import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/constants/app_colors.dart';
import 'package:flutter_pos/core/constants/app_sizes.dart';
import 'package:flutter_pos/core/constants/app_strings.dart';
import 'package:flutter_pos/core/utils/currency_formatter.dart';
import 'package:flutter_pos/core/utils/date_formatter.dart';
import 'package:flutter_pos/core/widgets/empty_state_widget.dart';
import 'package:flutter_pos/features/transactions/presentation/cubit/transaction_cubit.dart';
import 'package:flutter_pos/features/transactions/presentation/pages/transaction_detail_page.dart';

class TransactionListPage extends StatefulWidget {
  const TransactionListPage({super.key});

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  @override
  void initState() {
    super.initState();
    context.read<TransactionCubit>().loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.transactionHistory),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          return Column(
            children: [
              if (state.startDate != null) _buildDateFilter(state),
              Expanded(child: _buildContent(state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateFilter(TransactionState state) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md, vertical: AppSizes.sm),
      color: AppColors.primary.withOpacity(0.05),
      child: Row(
        children: [
          const Icon(Icons.date_range, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSizes.sm),
          Text(
            '${DateFormatter.formatShortDate(state.startDate!)} - '
            '${DateFormatter.formatShortDate(state.endDate ?? DateTime.now())}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => context.read<TransactionCubit>().clearFilter(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(TransactionState state) {
    if (state.status == TransactionStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.transactions.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.receipt_long_outlined,
        title: 'Belum ada transaksi',
        subtitle: 'Transaksi akan muncul setelah checkout',
      );
    }
    return RefreshIndicator(
      onRefresh: () => context.read<TransactionCubit>().loadTransactions(
            startDate: state.startDate,
            endDate: state.endDate,
          ),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.sm),
        itemCount: state.transactions.length,
        itemBuilder: (context, index) {
          final tx = state.transactions[index];
          return Card(
            margin: const EdgeInsets.symmetric(
                horizontal: AppSizes.sm, vertical: AppSizes.xs),
            child: ListTile(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TransactionDetailPage(transaction: tx),
                ),
              ),
              leading: CircleAvatar(
                backgroundColor: _getStatusColor(tx.status).withOpacity(0.1),
                child: Icon(
                  _getStatusIcon(tx.status),
                  color: _getStatusColor(tx.status),
                  size: 20,
                ),
              ),
              title: Text(
                tx.transactionNumber,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              subtitle: Text(
                tx.createdAt != null
                    ? DateFormatter.formatDateTime(tx.createdAt!)
                    : '-',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(tx.totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  _buildStatusBadge(tx.status),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    final label = switch (status) {
      'completed' => 'Selesai',
      'voided' => 'Void',
      'refunded' => 'Refund',
      _ => status,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Color _getStatusColor(String status) => switch (status) {
        'completed' => AppColors.success,
        'voided' => AppColors.error,
        'refunded' => AppColors.warning,
        _ => AppColors.textSecondary,
      };

  IconData _getStatusIcon(String status) => switch (status) {
        'completed' => Icons.check_circle_outline,
        'voided' => Icons.cancel_outlined,
        'refunded' => Icons.replay,
        _ => Icons.receipt_long,
      };

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      context.read<TransactionCubit>().setDateFilter(
            picked.start,
            picked.end,
          );
    }
  }
}
