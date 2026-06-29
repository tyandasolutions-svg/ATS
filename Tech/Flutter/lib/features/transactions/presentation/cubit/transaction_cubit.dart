import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_pos/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_pos/features/transactions/domain/repositories/transaction_repository.dart';

part 'transaction_state.dart';

class TransactionCubit extends Cubit<TransactionState> {
  final TransactionRepository _repository;

  TransactionCubit({required TransactionRepository repository})
      : _repository = repository,
        super(const TransactionState());

  Future<void> loadTransactions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    emit(state.copyWith(status: TransactionStatus.loading));

    final result = await _repository.getTransactions(
      startDate: startDate,
      endDate: endDate,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: TransactionStatus.error,
        errorMessage: failure.message,
      )),
      (transactions) => emit(state.copyWith(
        status: TransactionStatus.loaded,
        transactions: transactions,
      )),
    );
  }

  Future<TransactionEntity?> createTransaction(
      TransactionEntity transaction) async {
    final result = await _repository.createTransaction(transaction);
    return result.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.message));
        return null;
      },
      (tx) {
        loadTransactions();
        return tx;
      },
    );
  }

  Future<bool> voidTransaction(String id) async {
    final result = await _repository.voidTransaction(id);
    return result.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.message));
        return false;
      },
      (_) {
        loadTransactions();
        return true;
      },
    );
  }

  Future<bool> refundTransaction(String id) async {
    final result = await _repository.refundTransaction(id);
    return result.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.message));
        return false;
      },
      (_) {
        loadTransactions();
        return true;
      },
    );
  }

  void setDateFilter(DateTime? start, DateTime? end) {
    emit(state.copyWith(startDate: start, endDate: end));
    loadTransactions(startDate: start, endDate: end);
  }

  void clearFilter() {
    emit(state.copyWith(
      clearDateFilter: true,
    ));
    loadTransactions();
  }
}
