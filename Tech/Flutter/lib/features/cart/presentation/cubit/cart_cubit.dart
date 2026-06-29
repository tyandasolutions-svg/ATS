import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_pos/core/utils/helpers.dart';
import 'package:flutter_pos/features/cart/domain/entities/cart_item_entity.dart';
import 'package:flutter_pos/features/products/domain/entities/product_entity.dart';

part 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState());

  void addToCart(ProductEntity product, {int quantity = 1}) {
    final existingIndex =
        state.items.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      final existing = state.items[existingIndex];
      final updatedItems = List<CartItemEntity>.from(state.items);
      updatedItems[existingIndex] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
      emit(state.copyWith(items: updatedItems));
    } else {
      final newItem = CartItemEntity(
        id: AppHelpers.generateId(),
        product: product,
        unitPrice: product.price,
        quantity: quantity,
      );
      emit(state.copyWith(items: [...state.items, newItem]));
    }
  }

  void removeFromCart(String itemId) {
    final updatedItems =
        state.items.where((item) => item.id != itemId).toList();
    emit(state.copyWith(items: updatedItems));
  }

  void updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(itemId);
      return;
    }
    final updatedItems = state.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
    emit(state.copyWith(items: updatedItems));
  }

  void updateItemDiscount(
    String itemId, {
    required double discountValue,
    required bool isPercentage,
  }) {
    final updatedItems = state.items.map((item) {
      if (item.id == itemId) {
        final discountAmount = AppHelpers.calculateDiscount(
          amount: item.unitPrice,
          discount: discountValue,
          isPercentage: isPercentage,
        );
        return item.copyWith(
          discountAmount: discountAmount,
          isDiscountPercentage: isPercentage,
          discountValue: discountValue,
        );
      }
      return item;
    }).toList();
    emit(state.copyWith(items: updatedItems));
  }

  void updateItemNote(String itemId, String? note) {
    final updatedItems = state.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(note: note, clearNote: note == null);
      }
      return item;
    }).toList();
    emit(state.copyWith(items: updatedItems));
  }

  void setGlobalDiscount(double value, bool isPercentage) {
    emit(state.copyWith(
      globalDiscountValue: value,
      globalDiscountIsPercentage: isPercentage,
    ));
  }

  void setTaxPercentage(double percentage) {
    emit(state.copyWith(taxPercentage: percentage));
  }

  void clearCart() {
    emit(const CartState());
  }

  /// Hold current cart for later recall
  Map<String, dynamic> holdTransaction(String? note) {
    final holdData = {
      'items': List<CartItemEntity>.from(state.items),
      'discount': state.globalDiscountValue,
      'discountIsPercentage': state.globalDiscountIsPercentage,
      'note': note,
      'timestamp': DateTime.now(),
    };
    clearCart();
    return holdData;
  }

  /// Recall a held transaction
  void recallTransaction(List<CartItemEntity> items, {
    double discountValue = 0,
    bool discountIsPercentage = false,
  }) {
    emit(state.copyWith(
      items: items,
      globalDiscountValue: discountValue,
      globalDiscountIsPercentage: discountIsPercentage,
    ));
  }
}
