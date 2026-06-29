import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_pos/core/usecases/usecase.dart';
import 'package:flutter_pos/features/products/domain/entities/category_entity.dart';
import 'package:flutter_pos/features/products/domain/entities/product_entity.dart';
import 'package:flutter_pos/features/products/domain/usecases/product_usecases.dart';

part 'product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  final GetProductsUseCase _getProducts;
  final GetProductByBarcodeUseCase _getProductByBarcode;
  final CreateProductUseCase _createProduct;
  final UpdateProductUseCase _updateProduct;
  final DeleteProductUseCase _deleteProduct;
  final GetCategoriesUseCase _getCategories;

  Timer? _debounce;

  ProductCubit({
    required GetProductsUseCase getProducts,
    required GetProductByBarcodeUseCase getProductByBarcode,
    required CreateProductUseCase createProduct,
    required UpdateProductUseCase updateProduct,
    required DeleteProductUseCase deleteProduct,
    required GetCategoriesUseCase getCategories,
  })  : _getProducts = getProducts,
        _getProductByBarcode = getProductByBarcode,
        _createProduct = createProduct,
        _updateProduct = updateProduct,
        _deleteProduct = deleteProduct,
        _getCategories = getCategories,
        super(const ProductState());

  Future<void> loadProducts() async {
    emit(state.copyWith(status: ProductStatus.loading));
    final result = await _getProducts(GetProductsParams(
      categoryId: state.selectedCategoryId,
      searchQuery: state.searchQuery,
    ));
    result.fold(
      (failure) => emit(state.copyWith(
        status: ProductStatus.error,
        errorMessage: failure.message,
      )),
      (products) => emit(state.copyWith(
        status: ProductStatus.loaded,
        products: products,
      )),
    );
  }

  Future<void> loadCategories() async {
    final result = await _getCategories(const NoParams());
    result.fold(
      (_) {},
      (categories) => emit(state.copyWith(categories: categories)),
    );
  }

  void selectCategory(String? categoryId) {
    emit(state.copyWith(
      selectedCategoryId: categoryId,
      clearCategoryId: categoryId == null,
    ));
    loadProducts();
  }

  void searchProducts(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      emit(state.copyWith(searchQuery: query));
      loadProducts();
    });
  }

  Future<ProductEntity?> scanBarcode(String barcode) async {
    final result = await _getProductByBarcode(barcode);
    return result.fold((_) => null, (product) => product);
  }

  Future<bool> createProduct(ProductEntity product) async {
    final result = await _createProduct(product);
    return result.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.message));
        return false;
      },
      (_) {
        loadProducts();
        return true;
      },
    );
  }

  Future<bool> updateProduct(ProductEntity product) async {
    final result = await _updateProduct(product);
    return result.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.message));
        return false;
      },
      (_) {
        loadProducts();
        return true;
      },
    );
  }

  Future<bool> deleteProduct(String id) async {
    final result = await _deleteProduct(id);
    return result.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.message));
        return false;
      },
      (_) {
        loadProducts();
        return true;
      },
    );
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
