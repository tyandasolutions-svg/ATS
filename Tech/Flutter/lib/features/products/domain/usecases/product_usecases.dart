import 'package:dartz/dartz.dart';
import 'package:flutter_pos/core/errors/failures.dart';
import 'package:flutter_pos/core/usecases/usecase.dart';
import 'package:flutter_pos/features/products/domain/entities/category_entity.dart';
import 'package:flutter_pos/features/products/domain/entities/product_entity.dart';
import 'package:flutter_pos/features/products/domain/repositories/product_repository.dart';

class GetProductsUseCase
    implements UseCase<List<ProductEntity>, GetProductsParams> {
  final ProductRepository repository;
  const GetProductsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ProductEntity>>> call(
      GetProductsParams params) {
    return repository.getProducts(
      categoryId: params.categoryId,
      searchQuery: params.searchQuery,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class GetProductsParams {
  final String? categoryId;
  final String? searchQuery;
  final int limit;
  final int offset;

  const GetProductsParams({
    this.categoryId,
    this.searchQuery,
    this.limit = 50,
    this.offset = 0,
  });
}

class GetProductByBarcodeUseCase
    implements UseCase<ProductEntity?, String> {
  final ProductRepository repository;
  const GetProductByBarcodeUseCase(this.repository);

  @override
  Future<Either<Failure, ProductEntity?>> call(String barcode) {
    return repository.getProductByBarcode(barcode);
  }
}

class CreateProductUseCase
    implements UseCase<ProductEntity, ProductEntity> {
  final ProductRepository repository;
  const CreateProductUseCase(this.repository);

  @override
  Future<Either<Failure, ProductEntity>> call(ProductEntity product) {
    return repository.createProduct(product);
  }
}

class UpdateProductUseCase
    implements UseCase<ProductEntity, ProductEntity> {
  final ProductRepository repository;
  const UpdateProductUseCase(this.repository);

  @override
  Future<Either<Failure, ProductEntity>> call(ProductEntity product) {
    return repository.updateProduct(product);
  }
}

class DeleteProductUseCase implements UseCase<void, String> {
  final ProductRepository repository;
  const DeleteProductUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String id) {
    return repository.deleteProduct(id);
  }
}

class GetCategoriesUseCase
    implements UseCase<List<CategoryEntity>, NoParams> {
  final ProductRepository repository;
  const GetCategoriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<CategoryEntity>>> call(NoParams params) {
    return repository.getCategories();
  }
}
