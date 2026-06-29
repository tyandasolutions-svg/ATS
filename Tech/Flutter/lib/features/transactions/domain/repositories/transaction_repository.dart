import 'package:dartz/dartz.dart';
import 'package:flutter_pos/core/errors/failures.dart';
import 'package:flutter_pos/features/transactions/domain/entities/transaction_entity.dart';

abstract class TransactionRepository {
  Future<Either<Failure, TransactionEntity>> createTransaction(
      TransactionEntity transaction);
  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    int limit = 50,
    int offset = 0,
  });
  Future<Either<Failure, TransactionEntity>> getTransactionById(String id);
  Future<Either<Failure, void>> voidTransaction(String id);
  Future<Either<Failure, void>> refundTransaction(String id);
  Future<Either<Failure, Map<String, dynamic>>> getDailySummary(DateTime date);
  Future<Either<Failure, List<Map<String, dynamic>>>> getSalesReport({
    required DateTime startDate,
    required DateTime endDate,
  });
}
