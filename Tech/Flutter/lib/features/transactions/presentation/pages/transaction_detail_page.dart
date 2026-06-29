import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/constants/app_colors.dart';
import 'package:flutter_pos/core/constants/app_sizes.dart';
import 'package:flutter_pos/core/constants/app_strings.dart';
import 'package:flutter_pos/core/utils/currency_formatter.dart';
import 'package:flutter_pos/core/utils/date_formatter.dart';
import 'package:flutter_pos/core/widgets/app_snackbar.dart';
import 'package:flutter_pos/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_pos/features/transactions/presentation/cubit/transaction_cubit.dart';

class TransactionDetailPage extends StatelessWidget {
  final TransactionEntity transaction;

  const TransactionDetailPage({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.transactionDetail),
        actions: [
          if (transaction.isCompleted)
            PopupMenuButton<String>(
              onSelected: (value) => _onAction(context, value),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'void',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Void Transaksi'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'print',
                  child: Row(
                    children: [
                      Icon(Icons.print_outlined),
                      SizedBox(width: 8),
                      Text('Cetak Struk'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.md),
        children: [
          _buildHeader(context),
          const SizedBox(height: AppSizes.md),
          _buildItems(context),
          const SizedBox(height: AppSizes.md),
          _buildSummary(context),
          const SizedBox(height: AppSizes.md),
          _buildPaymentInfo(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  transaction.transactionNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                _buildStatusChip(),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            if (transaction.createdAt != null)
              Text(
                DateFormatter.formatDateTime(transaction.createdAt!),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            if (transaction.customerName != null) ...[
              const SizedBox(height: AppSizes.xs),
              Text('Pelanggan: ${transaction.customerName}'),
            ],
            if (transaction.note != null && transaction.note!.isNotEmpty) ...[
              const SizedBox(height: AppSizes.xs),
              Text(
                'Catatan: ${transaction.note}',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    final color = switch (transaction.status) {
      'completed' => AppColors.success,
      'voided' => AppColors.error,
      'refunded' => AppColors.warning,
      _ => AppColors.textSecondary,
    };
    final label = switch (transaction.status) {
      'completed' => 'Selesai',
      'voided' => 'Void',
      'refunded' => 'Refund',
      _ => transaction.status,
    };
    return Chip(
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide.none,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildItems(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item (${transaction.items.length})',
                style: Theme.of(context).textTheme.titleSmall),
            const Divider(),
            ...transaction.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                            Text(
                              '${item.quantity}x ${CurrencyFormatter.format(item.unitPrice)}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(item.totalPrice),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          children: [
            _summaryRow('Subtotal', transaction.subtotal),
            if (transaction.discountAmount > 0)
              _summaryRow('Diskon', -transaction.discountAmount,
                  color: AppColors.error),
            if (transaction.taxAmount > 0)
              _summaryRow(
                  'Pajak (${transaction.taxPercentage}%)', transaction.taxAmount),
            const Divider(),
            _summaryRow('Total', transaction.totalAmount, isBold: true),
            _summaryRow('Dibayar', transaction.paidAmount),
            if (transaction.changeAmount > 0)
              _summaryRow('Kembalian', transaction.changeAmount,
                  color: AppColors.success),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double amount,
      {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(BuildContext context) {
    if (transaction.payments.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Metode Pembayaran',
                style: Theme.of(context).textTheme.titleSmall),
            const Divider(),
            ...transaction.payments.map((p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_paymentLabel(p.method)),
                      Text(CurrencyFormatter.format(p.amount)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  String _paymentLabel(String method) => switch (method) {
        'cash' => 'Tunai',
        'qris' => 'QRIS',
        'transfer' => 'Transfer Bank',
        'ewallet' => 'E-Wallet',
        'card' => 'Kartu',
        _ => method,
      };

  void _onAction(BuildContext context, String action) {
    if (action == 'void') {
      _confirmVoid(context);
    } else if (action == 'print') {
      // TODO: Print receipt
      AppSnackbar.showInfo(context, 'Fitur cetak struk segera tersedia');
    }
  }

  void _confirmVoid(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void Transaksi'),
        content: Text(
            'Yakin ingin void transaksi ${transaction.transactionNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context
                  .read<TransactionCubit>()
                  .voidTransaction(transaction.id);
              if (context.mounted && success) {
                AppSnackbar.showSuccess(context, 'Transaksi berhasil di-void');
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Void'),
          ),
        ],
      ),
    );
  }
}
