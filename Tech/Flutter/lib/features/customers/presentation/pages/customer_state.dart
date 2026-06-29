part of 'customer_list_page.dart';

enum CustomerStatus { initial, loading, loaded, error }

class CustomerListState extends Equatable {
  final CustomerStatus status;
  final List<CustomerEntity> customers;
  final String? errorMessage;

  const CustomerListState({
    this.status = CustomerStatus.initial,
    this.customers = const [],
    this.errorMessage,
  });

  CustomerListState copyWith({
    CustomerStatus? status,
    List<CustomerEntity>? customers,
    String? errorMessage,
  }) {
    return CustomerListState(
      status: status ?? this.status,
      customers: customers ?? this.customers,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, customers, errorMessage];
}
