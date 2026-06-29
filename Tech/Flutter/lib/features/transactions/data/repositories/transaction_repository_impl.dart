import 'package:dartz/dartz.dart';
import 'package:flutter_pos/core/errors/exceptions.dart';
import 'package:flutter_pos/core/errors/failures.dart';
import 'package:flutter_pos/features/transactions/data/datasources/transaction_local_datasource.dart';
import 'package:flutter_pos/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_pos/features/transactions/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionLocalDataSource localDataSource;
  const TransactionRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, TransactionEntity>> createTransaction(
      TransactionEntity transaction) async {
    try {
      final result = await localDataSource.createTransaction(transaction);
      return Right(result);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final result = await localDataSource.getTransactions(
        startDate: startDate,
        endDate: endDate,
        status: status,
        limit: limit,
        offset: offset,
      );
      return Right(result);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, TransactionEntity>> getTransactionById(
      String id) async {
    try {
      return Right(await localDataSource.getTransactionById(id));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> voidTransaction(String id) async {
    try {
      await localDataSource.voidTransaction(id);
      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> refundTransaction(String id) async {
    try {
      await localDataSource.refundTransaction(id);
      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getDailySummary(
      DateTime date) async {
    try {
      return Right(await localDataSource.getDailySummary(date));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getSalesReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final result = await localDataSource.getBestSellingProducts(
        startDate: startDate,
        endDate: endDate,
      );
      return Right(result);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    }
  }
}
