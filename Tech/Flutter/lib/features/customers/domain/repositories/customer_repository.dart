import 'package:dartz/dartz.dart';
import 'package:flutter_pos/core/errors/failures.dart';
import 'package:flutter_pos/features/customers/domain/entities/customer_entity.dart';

abstract class CustomerRepository {
  Future<Either<Failure, List<CustomerEntity>>> getCustomers({
    String? searchQuery,
  });
  Future<Either<Failure, CustomerEntity>> createCustomer(CustomerEntity c);
  Future<Either<Failure, CustomerEntity>> updateCustomer(CustomerEntity c);
  Future<Either<Failure, void>> deleteCustomer(String id);
  Future<Either<Failure, void>> addLoyaltyPoints(String id, int points);
}
