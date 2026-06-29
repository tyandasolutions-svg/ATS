part of 'cart_cubit.dart';

class CartState extends Equatable {
  final List<CartItemEntity> items;
  final double globalDiscountValue;
  final bool globalDiscountIsPercentage;
  final double taxPercentage;

  const CartState({
    this.items = const [],
    this.globalDiscountValue = 0,
    this.globalDiscountIsPercentage = false,
    this.taxPercentage = 11.0,
  });

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  int get uniqueItems => items.length;
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.subtotal);

  double get itemDiscountTotal =>
      items.fold(0.0, (sum, item) => sum + item.totalDiscount);

  double get globalDiscount {
    final afterItemDiscount = subtotal - itemDiscountTotal;
    if (globalDiscountIsPercentage) {
      return afterItemDiscount * (globalDiscountValue / 100);
    }
    return globalDiscountValue;
  }

  double get totalDiscount => itemDiscountTotal + globalDiscount;

  double get taxableAmount => subtotal - totalDiscount;

  double get taxAmount => taxableAmount * (taxPercentage / 100);

  double get totalAmount => taxableAmount + taxAmount;

  int get totalAmountRounded => totalAmount.round();

  CartState copyWith({
    List<CartItemEntity>? items,
    double? globalDiscountValue,
    bool? globalDiscountIsPercentage,
    double? taxPercentage,
  }) {
    return CartState(
      items: items ?? this.items,
      globalDiscountValue: globalDiscountValue ?? this.globalDiscountValue,
      globalDiscountIsPercentage:
          globalDiscountIsPercentage ?? this.globalDiscountIsPercentage,
      taxPercentage: taxPercentage ?? this.taxPercentage,
    );
  }

  @override
  List<Object?> get props => [
        items,
        globalDiscountValue,
        globalDiscountIsPercentage,
        taxPercentage,
      ];
}
