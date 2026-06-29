import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/constants/app_colors.dart';
import 'package:flutter_pos/core/constants/app_sizes.dart';
import 'package:flutter_pos/core/constants/app_strings.dart';
import 'package:flutter_pos/core/utils/currency_formatter.dart';
import 'package:flutter_pos/core/utils/helpers.dart';
import 'package:flutter_pos/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:flutter_pos/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_pos/features/transactions/presentation/cubit/transaction_cubit.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _selectedMethod = 'cash';
  final _cashController = TextEditingController();
  final List<int> _quickAmounts = [
    10000, 20000, 50000, 100000, 150000, 200000, 500000,
  ];

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  int get _paidAmount {
    if (_selectedMethod != 'cash') return 0;
    final parsed = CurrencyFormatter.parse(_cashController.text);
    return parsed?.toInt() ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        final total = cartState.totalAmountRounded;

        return Scaffold(
          appBar: AppBar(title: const Text(AppStrings.payment)),
          body: ListView(
            padding: const EdgeInsets.all(AppSizes.md),
            children: [
              _buildTotalCard(total),
              const SizedBox(height: AppSizes.md),
              _buildPaymentMethods(),
              if (_selectedMethod == 'cash') ...[
                const SizedBox(height: AppSizes.md),
                _buildCashInput(total),
                const SizedBox(height: AppSizes.md),
                _buildQuickAmounts(total),
              ],
              const SizedBox(height: AppSizes.xl),
              _buildPayButton(total),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTotalCard(int total) {
    return Card(
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          children: [
            const Text(
              AppStrings.total,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              CurrencyFormatter.format(total),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    const methods = [
      {'key': 'cash', 'label': AppStrings.cash, 'icon': Icons.money},
      {'key': 'qris', 'label': AppStrings.qris, 'icon': Icons.qr_code},
      {'key': 'transfer', 'label': AppStrings.transfer, 'icon': Icons.account_balance},
      {'key': 'ewallet', 'label': AppStrings.eWallet, 'icon': Icons.account_balance_wallet},
      {'key': 'card', 'label': AppStrings.card, 'icon': Icons.credit_card},
    ];

    return Wrap(
      spacing: AppSizes.sm,
      runSpacing: AppSizes.sm,
      children: methods.map((m) {
        final key = m['key'] as String;
        final isSelected = _selectedMethod == key;
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                m['icon'] as IconData,
                size: 18,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(m['label'] as String),
            ],
          ),
          selected: isSelected,
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
          onSelected: (_) => setState(() {
            _selectedMethod = key;
            _cashController.clear();
          }),
        );
      }).toList(),
    );
  }

  Widget _buildCashInput(int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Jumlah Uang Diterima',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSizes.sm),
        TextField(
          controller: _cashController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            prefixText: 'Rp ',
            hintText: '0',
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (_paidAmount > 0 && _paidAmount >= total) ...[
          const SizedBox(height: AppSizes.sm),
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(AppStrings.change,
                    style: TextStyle(fontSize: 16)),
                Text(
                  CurrencyFormatter.format(_paidAmount - total),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickAmounts(int total) {
    // Add exact amount at the beginning
    final amounts = [total, ..._quickAmounts.where((a) => a >= total)];
    final uniqueAmounts = amounts.toSet().toList()..sort();

    return Wrap(
      spacing: AppSizes.sm,
      runSpacing: AppSizes.sm,
      children: uniqueAmounts.map((amount) {
        return OutlinedButton(
          onPressed: () {
            _cashController.text = amount.toString();
            setState(() {});
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md, vertical: AppSizes.sm),
          ),
          child: Text(
            amount == total
                ? 'Uang Pas'
                : CurrencyFormatter.format(amount),
            style: TextStyle(
              fontWeight:
                  amount == total ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPayButton(int total) {
    final canPay = _selectedMethod != 'cash' || _paidAmount >= total;

    return ElevatedButton(
      onPressed: canPay
          ? () {
              _processPayment(total);
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.success,
        padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
      ),
      child: const Text(
        AppStrings.payNow,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _processPayment(int total) {
    final cartState = context.read<CartCubit>().state;
    final txId = AppHelpers.generateId();
    final txNumber = AppHelpers.generateTransactionNumber();

    // Build transaction items from cart
    final items = cartState.items.map((item) {
      return TransactionItemEntity(
        id: AppHelpers.generateId(),
        transactionId: txId,
        productId: item.product.id,
        productName: item.product.name,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        discountAmount: item.totalDiscount,
        totalPrice: item.subtotal - item.totalDiscount,
        note: item.note,
      );
    }).toList();

    // Build payment method
    final payments = [
      PaymentMethodEntity(
        id: AppHelpers.generateId(),
        transactionId: txId,
        method: _selectedMethod,
        amount: _selectedMethod == 'cash'
            ? _paidAmount.toDouble()
            : total.toDouble(),
      ),
    ];

    final transaction = TransactionEntity(
      id: txId,
      transactionNumber: txNumber,
      userId: 'admin', // TODO: get from AuthCubit
      subtotal: cartState.subtotal,
      discountAmount: cartState.totalDiscount,
      taxAmount: cartState.taxAmount,
      taxPercentage: cartState.taxPercentage,
      totalAmount: total.toDouble(),
      paidAmount: _selectedMethod == 'cash'
          ? _paidAmount.toDouble()
          : total.toDouble(),
      changeAmount: _selectedMethod == 'cash'
          ? (_paidAmount - total).toDouble()
          : 0,
      status: 'completed',
      items: items,
      payments: payments,
      createdAt: DateTime.now(),
    );

    context.read<TransactionCubit>().createTransaction(transaction);
    context.read<CartCubit>().clearCart();
    _showSuccessDialog(total);
  }

  void _showSuccessDialog(int total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 64),
            const SizedBox(height: AppSizes.md),
            const Text(
              'Pembayaran Berhasil!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(CurrencyFormatter.format(total),
                style: const TextStyle(fontSize: 24, color: AppColors.primary)),
            if (_selectedMethod == 'cash' && _paidAmount > total) ...[
              const SizedBox(height: AppSizes.sm),
              Text(
                'Kembalian: ${CurrencyFormatter.format(_paidAmount - total)}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Print receipt
            },
            icon: const Icon(Icons.print),
            label: const Text(AppStrings.printReceipt),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Transaksi Baru'),
          ),
        ],
      ),
    );
  }
}
