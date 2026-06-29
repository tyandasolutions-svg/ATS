import 'package:drift/drift.dart';
import 'package:flutter_pos/core/database/app_database.dart';
import 'package:flutter_pos/core/errors/exceptions.dart';
import 'package:flutter_pos/features/customers/domain/entities/customer_entity.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_pos/core/errors/failures.dart';
import 'package:flutter_pos/features/customers/domain/repositories/customer_repository.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final AppDatabase _db;
  const CustomerRepositoryImpl(this._db);

  @override
  Future<Either<Failure, List<CustomerEntity>>> getCustomers({
    String? searchQuery,
  }) async {
    try {
      final query = _db.select(_db.customers)
        ..orderBy([(c) => OrderingTerm.asc(c.name)]);

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query.where((c) =>
            c.name.like('%$searchQuery%') |
            c.phone.like('%$searchQuery%'));
      }

      final results = await query.get();
      return Right(results
          .map((c) => CustomerEntity(
                id: c.id,
                name: c.name,
                phone: c.phone,
                email: c.email,
                address: c.address,
                loyaltyPoints: c.loyaltyPoints,
                createdAt: c.createdAt,
              ))
          .toList());
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, CustomerEntity>> createCustomer(
      CustomerEntity c) async {
    try {
      await _db.into(_db.customers).insert(CustomersCompanion.insert(
            id: c.id,
            name: c.name,
            phone: Value(c.phone),
            email: Value(c.email),
            address: Value(c.address),
            createdAt: Value(DateTime.now()),
          ));
      return Right(c);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, CustomerEntity>> updateCustomer(
      CustomerEntity c) async {
    try {
      await (_db.update(_db.customers)..where((t) => t.id.equals(c.id)))
          .write(CustomersCompanion(
        name: Value(c.name),
        phone: Value(c.phone),
        email: Value(c.email),
        address: Value(c.address),
        updatedAt: Value(DateTime.now()),
      ));
      return Right(c);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomer(String id) async {
    try {
      await (_db.delete(_db.customers)..where((c) => c.id.equals(id))).go();
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addLoyaltyPoints(
      String id, int points) async {
    try {
      final customer = await (_db.select(_db.customers)
            ..where((c) => c.id.equals(id)))
          .getSingle();
      await (_db.update(_db.customers)..where((c) => c.id.equals(id)))
          .write(CustomersCompanion(
        loyaltyPoints: Value(customer.loyaltyPoints + points),
      ));
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }
}
