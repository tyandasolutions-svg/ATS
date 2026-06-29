import 'package:equatable/equatable.dart';

class TransactionEntity extends Equatable {
  final String id;
  final String transactionNumber;
  final String userId;
  final String? customerId;
  final String? customerName;
  final double subtotal;
  final double discountAmount;
  final double discountPercentage;
  final double taxAmount;
  final double taxPercentage;
  final double totalAmount;
  final double paidAmount;
  final double changeAmount;
  final String status; // completed, voided, refunded
  final String? note;
  final bool isSynced;
  final List<TransactionItemEntity> items;
  final List<PaymentMethodEntity> payments;
  final DateTime? createdAt;

  const TransactionEntity({
    required this.id,
    required this.transactionNumber,
    required this.userId,
    this.customerId,
    this.customerName,
    required this.subtotal,
    this.discountAmount = 0,
    this.discountPercentage = 0,
    this.taxAmount = 0,
    this.taxPercentage = 0,
    required this.totalAmount,
    required this.paidAmount,
    this.changeAmount = 0,
    this.status = 'completed',
    this.note,
    this.isSynced = false,
    this.items = const [],
    this.payments = const [],
    this.createdAt,
  });

  bool get isCompleted => status == 'completed';
  bool get isVoided => status == 'voided';
  bool get isRefunded => status == 'refunded';

  @override
  List<Object?> get props => [id, transactionNumber, status];
}

class TransactionItemEntity extends Equatable {
  final String id;
  final String transactionId;
  final String productId;
  final String? variantId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double discountAmount;
  final double totalPrice;
  final String? note;

  const TransactionItemEntity({
    required this.id,
    required this.transactionId,
    required this.productId,
    this.variantId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.discountAmount = 0,
    required this.totalPrice,
    this.note,
  });

  @override
  List<Object?> get props => [id, productId, quantity];
}

class PaymentMethodEntity extends Equatable {
  final String id;
  final String transactionId;
  final String method;
  final double amount;
  final String? reference;

  const PaymentMethodEntity({
    required this.id,
    required this.transactionId,
    required this.method,
    required this.amount,
    this.reference,
  });

  @override
  List<Object?> get props => [id, method, amount];
}
