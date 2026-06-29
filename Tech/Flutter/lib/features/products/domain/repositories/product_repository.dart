import 'package:dartz/dartz.dart';
import 'package:flutter_pos/core/errors/failures.dart';
import 'package:flutter_pos/features/products/domain/entities/category_entity.dart';
import 'package:flutter_pos/features/products/domain/entities/product_entity.dart';

abstract class ProductRepository {
  Future<Either<Failure, List<ProductEntity>>> getProducts({
    String? categoryId,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  });

  Future<Either<Failure, ProductEntity>> getProductById(String id);
  Future<Either<Failure, ProductEntity?>> getProductByBarcode(String barcode);
  Future<Either<Failure, ProductEntity>> createProduct(ProductEntity product);
  Future<Either<Failure, ProductEntity>> updateProduct(ProductEntity product);
  Future<Either<Failure, void>> deleteProduct(String id);
  Future<Either<Failure, void>> updateStock(String id, int quantity);

  // Categories
  Future<Either<Failure, List<CategoryEntity>>> getCategories();
  Future<Either<Failure, CategoryEntity>> createCategory(CategoryEntity cat);
  Future<Either<Failure, CategoryEntity>> updateCategory(CategoryEntity cat);
  Future<Either<Failure, void>> deleteCategory(String id);
}
