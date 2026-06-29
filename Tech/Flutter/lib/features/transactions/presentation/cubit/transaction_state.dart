part of 'transaction_cubit.dart';

enum TransactionStatus { initial, loading, loaded, error }

class TransactionState extends Equatable {
  final TransactionStatus status;
  final List<TransactionEntity> transactions;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? errorMessage;

  const TransactionState({
    this.status = TransactionStatus.initial,
    this.transactions = const [],
    this.startDate,
    this.endDate,
    this.errorMessage,
  });

  TransactionState copyWith({
    TransactionStatus? status,
    List<TransactionEntity>? transactions,
    DateTime? startDate,
    DateTime? endDate,
    bool clearDateFilter = false,
    String? errorMessage,
  }) {
    return TransactionState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      startDate: clearDateFilter ? null : startDate ?? this.startDate,
      endDate: clearDateFilter ? null : endDate ?? this.endDate,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, transactions, startDate, endDate, errorMessage];
}
