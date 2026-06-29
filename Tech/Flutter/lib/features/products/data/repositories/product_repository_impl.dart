import 'package:dartz/dartz.dart';
import 'package:flutter_pos/core/errors/exceptions.dart';
import 'package:flutter_pos/core/errors/failures.dart';
import 'package:flutter_pos/features/products/data/datasources/product_local_datasource.dart';
import 'package:flutter_pos/features/products/domain/entities/category_entity.dart';
import 'package:flutter_pos/features/products/domain/entities/product_entity.dart';
import 'package:flutter_pos/features/products/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductLocalDataSource localDataSource;
  const ProductRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts({
    String? categoryId,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final products = await localDataSource.getProducts(
        categoryId: categoryId,
        searchQuery: searchQuery,
        limit: limit,
        offset: offset,
      );
      return Right(products);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> getProductById(String id) async {
    try {
      return Right(await localDataSource.getProductById(id));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, ProductEntity?>> getProductByBarcode(
      String barcode) async {
    try {
      return Right(await localDataSource.getProductByBarcode(barcode));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> createProduct(
      ProductEntity product) async {
    try {
      return Right(await localDataSource.createProduct(product));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> updateProduct(
      ProductEntity product) async {
    try {
      return Right(await localDataSource.updateProduct(product));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    try {
      await localDataSource.deleteProduct(id);
      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateStock(
      String id, int quantity) async {
    try {
      await localDataSource.updateStock(id, quantity);
      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() async {
    try {
      return Right(await localDataSource.getCategories());
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, CategoryEntity>> createCategory(
      CategoryEntity cat) async {
    try {
      return Right(await localDataSource.createCategory(cat));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, CategoryEntity>> updateCategory(
      CategoryEntity cat) async {
    try {
      return Right(await localDataSource.updateCategory(cat));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(String id) async {
    try {
      await localDataSource.deleteCategory(id);
      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    }
  }
}
