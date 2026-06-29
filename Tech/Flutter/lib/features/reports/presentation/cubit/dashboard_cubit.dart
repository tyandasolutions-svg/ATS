import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_pos/features/transactions/domain/repositories/transaction_repository.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final TransactionRepository _repository;

  DashboardCubit({required TransactionRepository repository})
      : _repository = repository,
        super(const DashboardState());

  Future<void> loadDashboard() async {
    emit(state.copyWith(status: DashboardStatus.loading));

    final today = DateTime.now();
    final summaryResult = await _repository.getDailySummary(today);

    // Get last 7 days for chart
    final weekData = <DaySales>[];
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final result = await _repository.getDailySummary(date);
      result.fold((_) {}, (data) {
        weekData.add(DaySales(
          date: date,
          totalSales: (data['total_sales'] as num).toDouble(),
          totalTransactions: data['total_transactions'] as int,
        ));
      });
    }

    // Get best selling products
    final startOfMonth = DateTime(today.year, today.month, 1);
    final bestSellingResult = await _repository.getSalesReport(
      startDate: startOfMonth,
      endDate: today,
    );

    summaryResult.fold(
      (failure) => emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: failure.message,
      )),
      (summary) {
        final bestSelling = bestSellingResult.fold(
          (_) => <Map<String, dynamic>>[],
          (data) => data,
        );

        emit(state.copyWith(
          status: DashboardStatus.loaded,
          totalSales: (summary['total_sales'] as num).toDouble(),
          totalTransactions: summary['total_transactions'] as int,
          totalItems: summary['total_items'] as int,
          averageTransaction:
              (summary['average_transaction'] as num).toDouble(),
          weeklyData: weekData,
          bestSellingProducts: bestSelling,
        ));
      },
    );
  }
}
