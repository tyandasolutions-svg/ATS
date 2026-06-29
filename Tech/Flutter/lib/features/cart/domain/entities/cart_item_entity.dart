import 'package:equatable/equatable.dart';
import 'package:flutter_pos/features/products/domain/entities/product_entity.dart';

class CartItemEntity extends Equatable {
  final String id;
  final ProductEntity product;
  final String? variantId;
  final int quantity;
  final double unitPrice;
  final double discountAmount;
  final bool isDiscountPercentage;
  final double discountValue;
  final String? note;

  const CartItemEntity({
    required this.id,
    required this.product,
    this.variantId,
    this.quantity = 1,
    required this.unitPrice,
    this.discountAmount = 0,
    this.isDiscountPercentage = false,
    this.discountValue = 0,
    this.note,
  });

  double get subtotal => unitPrice * quantity;
  double get totalDiscount => discountAmount * quantity;
  double get totalPrice => subtotal - totalDiscount;

  CartItemEntity copyWith({
    int? quantity,
    double? discountAmount,
    bool? isDiscountPercentage,
    double? discountValue,
    String? note,
    bool clearNote = false,
  }) {
    return CartItemEntity(
      id: id,
      product: product,
      variantId: variantId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice,
      discountAmount: discountAmount ?? this.discountAmount,
      isDiscountPercentage: isDiscountPercentage ?? this.isDiscountPercentage,
      discountValue: discountValue ?? this.discountValue,
      note: clearNote ? null : note ?? this.note,
    );
  }

  @override
  List<Object?> get props =>
      [id, product.id, variantId, quantity, unitPrice, discountAmount, note];
}
