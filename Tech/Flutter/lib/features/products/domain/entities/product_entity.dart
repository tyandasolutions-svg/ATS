import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? sku;
  final String? barcode;
  final double price;
  final double costPrice;
  final int stock;
  final String? categoryId;
  final String? categoryName;
  final String? imagePath;
  final bool isActive;
  final bool trackStock;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductEntity({
    required this.id,
    required this.name,
    this.description,
    this.sku,
    this.barcode,
    required this.price,
    this.costPrice = 0,
    this.stock = 0,
    this.categoryId,
    this.categoryName,
    this.imagePath,
    this.isActive = true,
    this.trackStock = true,
    this.createdAt,
    this.updatedAt,
  });

  bool get isLowStock => trackStock && stock <= 5 && stock > 0;
  bool get isOutOfStock => trackStock && stock <= 0;

  @override
  List<Object?> get props => [id, name, price, stock, categoryId, isActive];
}
