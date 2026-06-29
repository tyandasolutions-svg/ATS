part of 'dashboard_cubit.dart';

enum DashboardStatus { initial, loading, loaded, error }

class DaySales extends Equatable {
  final DateTime date;
  final double totalSales;
  final int totalTransactions;

  const DaySales({
    required this.date,
    required this.totalSales,
    required this.totalTransactions,
  });

  @override
  List<Object?> get props => [date, totalSales, totalTransactions];
}

class DashboardState extends Equatable {
  final DashboardStatus status;
  final double totalSales;
  final int totalTransactions;
  final int totalItems;
  final double averageTransaction;
  final List<DaySales> weeklyData;
  final List<Map<String, dynamic>> bestSellingProducts;
  final String? errorMessage;

  const DashboardState({
    this.status = DashboardStatus.initial,
    this.totalSales = 0,
    this.totalTransactions = 0,
    this.totalItems = 0,
    this.averageTransaction = 0,
    this.weeklyData = const [],
    this.bestSellingProducts = const [],
    this.errorMessage,
  });

  DashboardState copyWith({
    DashboardStatus? status,
    double? totalSales,
    int? totalTransactions,
    int? totalItems,
    double? averageTransaction,
    List<DaySales>? weeklyData,
    List<Map<String, dynamic>>? bestSellingProducts,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      totalSales: totalSales ?? this.totalSales,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      totalItems: totalItems ?? this.totalItems,
      averageTransaction: averageTransaction ?? this.averageTransaction,
      weeklyData: weeklyData ?? this.weeklyData,
      bestSellingProducts: bestSellingProducts ?? this.bestSellingProducts,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        totalSales,
        totalTransactions,
        totalItems,
        averageTransaction,
        weeklyData,
        bestSellingProducts,
        errorMessage,
      ];
}
