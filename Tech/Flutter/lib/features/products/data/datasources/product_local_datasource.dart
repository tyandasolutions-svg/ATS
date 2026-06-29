import 'package:drift/drift.dart';
import 'package:flutter_pos/core/database/app_database.dart';
import 'package:flutter_pos/core/errors/exceptions.dart';
import 'package:flutter_pos/features/products/domain/entities/category_entity.dart';
import 'package:flutter_pos/features/products/domain/entities/product_entity.dart';

abstract class ProductLocalDataSource {
  Future<List<ProductEntity>> getProducts({
    String? categoryId,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  });
  Future<ProductEntity> getProductById(String id);
  Future<ProductEntity?> getProductByBarcode(String barcode);
  Future<ProductEntity> createProduct(ProductEntity product);
  Future<ProductEntity> updateProduct(ProductEntity product);
  Future<void> deleteProduct(String id);
  Future<void> updateStock(String id, int quantity);
  Future<List<CategoryEntity>> getCategories();
  Future<CategoryEntity> createCategory(CategoryEntity cat);
  Future<CategoryEntity> updateCategory(CategoryEntity cat);
  Future<void> deleteCategory(String id);
}

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final AppDatabase _db;
  const ProductLocalDataSourceImpl(this._db);

  @override
  Future<List<ProductEntity>> getProducts({
    String? categoryId,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final query = _db.select(_db.products).join([
        leftOuterJoin(
          _db.categories,
          _db.categories.id.equalsExp(_db.products.categoryId),
        ),
      ]);

      if (categoryId != null) {
        query.where(_db.products.categoryId.equals(categoryId));
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query.where(
          _db.products.name.like('%$searchQuery%') |
              _db.products.sku.like('%$searchQuery%') |
              _db.products.barcode.like('%$searchQuery%'),
        );
      }
      query.where(_db.products.isActive.equals(true));
      query
        ..orderBy([OrderingTerm.asc(_db.products.name)])
        ..limit(limit, offset: offset);

      final results = await query.get();
      return results.map((row) {
        final p = row.readTable(_db.products);
        final c = row.readTableOrNull(_db.categories);
        return ProductEntity(
          id: p.id,
          name: p.name,
          description: p.description,
          sku: p.sku,
          barcode: p.barcode,
          price: p.price,
          costPrice: p.costPrice,
          stock: p.stock,
          categoryId: p.categoryId,
          categoryName: c?.name,
          imagePath: p.imagePath,
          isActive: p.isActive,
          trackStock: p.trackStock,
          createdAt: p.createdAt,
          updatedAt: p.updatedAt,
        );
      }).toList();
    } catch (e) {
      throw DatabaseException(message: e.toString());
    }
  }

  @override
  Future<ProductEntity> getProductById(String id) async {
    try {
      final query = _db.select(_db.products)
        ..where((p) => p.id.equals(id));
      final result = await query.getSingleOrNull();
      if (result == null) {
        throw const DatabaseException(message: 'Produk tidak ditemukan');
      }
      return ProductEntity(
        id: result.id,
        name: result.name,
        description: result.description,
        sku: result.sku,
        barcode: result.barcode,
        price: result.price,
        costPrice: result.costPrice,
        stock: result.stock,
        categoryId: result.categoryId,
        imagePath: result.imagePath,
        isActive: result.isActive,
        trackStock: result.trackStock,
        createdAt: result.createdAt,
        updatedAt: result.updatedAt,
      );
    } catch (e) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException(message: e.toString());
    }
  }

  @override
  Future<ProductEntity?> getProductByBarcode(String barcode) async {
    try {
      final query = _db.select(_db.products)
        ..where((p) => p.barcode.equals(barcode))
        ..where((p) => p.isActive.equals(true));
      final result = await query.getSingleOrNull();
      if (result == null) return null;
      return ProductEntity(
        id: result.id,
        name: result.name,
        description: result.description,
        sku: result.sku,
        barcode: result.barcode,
        price: result.price,
        costPrice: result.costPrice,
        stock: result.stock,
        categoryId: result.categoryId,
        imagePath: result.imagePath,
        isActive: result.isActive,
        trackStock: result.trackStock,
        createdAt: result.createdAt,
      );
    } catch (e) {
      throw DatabaseException(message: e.toString());
    }
  }

  @override
  Future<ProductEntity> createProduct(ProductEntity product) async {
    try {
      await _db.into(_db.products).insert(ProductsCompanion.insert(
            id: product.id,
            name: product.name,
            description: Value(product.description),
            sku: Value(product.sku),
            barcode: Value(product.barcode),
            price: product.price,
            costPrice: Value(product.costPrice),
            stock: Value(product.stock),
            categoryId: Value(product.categoryId),
            imagePath: Value(product.imagePath),
            isActive: Value(product.isActive),
            trackStock: Value(product.trackStock),
            createdAt: Value(DateTime.now()),
          ));
      return product;
    } catch (e) {
      throw DatabaseException(message: e.toString());
    }
  }

  @override
  Future<ProductEntity> updateProduct(ProductEntity product) async {
    try {
      await (_db.update(_db.products)
            ..where((p) => p.id.equals(product.id)))
          .write(ProductsCompanion(
        name: Value(product.name),
        description: Value(product.description),
        sku: Value(product.sku),
        barcode: Value(product.barcode),
        price: Value(product.price),
        costPrice: Value(product.costPrice),
        stock: Value(product.stock),
        categoryId: Value(product.categoryId),
        imagePath: Value(product.imagePath),
        isActive: Value(product.isActive),
        trackStock: Value(product.trackStock),
        updatedAt: Value(DateTime.now()),
      ));
      return product;
    } catch (e) {
      throw DatabaseException(message: e.toString());
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      await (_db.update(_db.products)..where((p) => p.id.equals(id)))
          .write(const ProductsCompanion(isActive: Value(false)));
    } catch (e) {
      throw DatabaseException(message: e.toString());
    }
  }

  @override
  Future<void> updateStock(String id, int quantity) async {
    try {
      final product = await getProductById(id);
      final newStock = product.stock + quantity;
      await (_db.update(_db.products)..where((p) => p.id.equals(id)))
          .write(ProductsCompanion(stock: Value(newStock)));
    } catch (e) {
      throw DatabaseException(message: e.toString());
    }
  }

  @override
  Future<List<CategoryEntity>> getCategories() async {
    try {
      final results = await (_db.select(_db.categories)
            ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
          .get();
      return results
          .map((c) => CategoryEntity(
                id: c.id,
                name: c.name,
                parentId: c.parentId,
                iconName: c.iconName,
                sortOrder: c.sortOrder,
                createdAt: c.createdAt,
              ))
          .toList();
    } catch (e) {
      throw DatabaseException(message: e.toString());
    }
  }

  @override
  Future<CategoryEntity> createCategory(CategoryEntity cat) async {
    try {
      await _db.into(_db.categories).insert(CategoriesCompanion.insert(
            id: cat.id,
            name: cat.name,
            parentId: Value(cat.parentId),
            iconName: Value(cat.iconName),
            sortOrder: Value(cat.sortOrder),
            createdAt: Value(DateTime.now()),
          ));
      return cat;
    } catch (e) {
      throw DatabaseException(message: e.toString());
    }
  }

  @override
  Future<CategoryEntity> updateCategory(CategoryEntity cat) async {
    try {
      await (_db.update(_db.categories)..where((c) => c.id.equals(cat.id)))
          .write(CategoriesCompanion(
        name: Value(cat.name),
        parentId: Value(cat.parentId),
        iconName: Value(cat.iconName),
        sortOrder: Value(cat.sortOrder),
      ));
      return cat;
    } catch (e) {
      throw DatabaseException(message: e.toString());
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await (_db.delete(_db.categories)..where((c) => c.id.equals(id))).go();
    } catch (e) {
      throw DatabaseException(message: e.toString());
    }
  }
}
