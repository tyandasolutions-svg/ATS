import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/constants/app_colors.dart';
import 'package:flutter_pos/core/constants/app_sizes.dart';
import 'package:flutter_pos/core/constants/app_strings.dart';
import 'package:flutter_pos/core/utils/currency_formatter.dart';
import 'package:flutter_pos/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:flutter_pos/features/cart/presentation/widgets/cart_item_tile.dart';
import 'package:flutter_pos/features/cart/presentation/pages/payment_page.dart';
import 'package:flutter_pos/features/products/presentation/cubit/product_cubit.dart';
import 'package:flutter_pos/features/products/presentation/widgets/category_chips.dart';
import 'package:flutter_pos/features/products/presentation/widgets/product_card.dart';

class CashierPage extends StatefulWidget {
  const CashierPage({super.key});

  @override
  State<CashierPage> createState() => _CashierPageState();
}

class _CashierPageState extends State<CashierPage> {
  final _searchController = TextEditingController();
  bool _showCart = false;

  @override
  void initState() {
    super.initState();
    context.read<ProductCubit>().loadProducts();
    context.read<ProductCubit>().loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > AppSizes.tabletBreakpoint;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.cashier),
        actions: [
          if (!isWide)
            BlocBuilder<CartCubit, CartState>(
              builder: (context, state) {
                return Badge(
                  label: Text('${state.totalItems}'),
                  isLabelVisible: state.isNotEmpty,
                  child: IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () => setState(() => _showCart = !_showCart),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              // TODO: Barcode scanner
            },
          ),
        ],
      ),
      body: isWide ? _buildTabletLayout() : _buildPhoneLayout(),
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        Expanded(flex: 3, child: _buildProductSection()),
        const VerticalDivider(width: 1),
        Expanded(flex: 2, child: _buildCartSection()),
      ],
    );
  }

  Widget _buildPhoneLayout() {
    if (_showCart) {
      return _buildCartSection();
    }
    return _buildProductSection();
  }

  Widget _buildProductSection() {
    return Column(
      children: [
        _buildSearchBar(),
        const CategoryChips(),
        const SizedBox(height: AppSizes.sm),
        Expanded(child: _buildProductGrid()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.md, AppSizes.sm, AppSizes.md, 0,
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: AppStrings.searchProduct,
          prefixIcon: const Icon(Icons.search),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    context.read<ProductCubit>().searchProducts('');
                    setState(() {});
                  },
                )
              : null,
        ),
        onChanged: (v) {
          context.read<ProductCubit>().searchProducts(v);
          setState(() {});
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    return BlocBuilder<ProductCubit, ProductState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status || prev.products != curr.products,
      builder: (context, state) {
        if (state.status == ProductStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.products.isEmpty) {
          return const Center(child: Text('Tidak ada produk'));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(AppSizes.sm),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
                MediaQuery.of(context).size.width > AppSizes.tabletBreakpoint
                    ? 3
                    : 2,
            childAspectRatio: 0.78,
            crossAxisSpacing: AppSizes.sm,
            mainAxisSpacing: AppSizes.sm,
          ),
          itemCount: state.products.length,
          itemBuilder: (context, index) {
            final product = state.products[index];
            return ProductCard(
              product: product,
              onAddToCart: () {
                context.read<CartCubit>().addToCart(product);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCartSection() {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        return Column(
          children: [
            if (!MediaQuery.of(context).size.width
                .isFinite || MediaQuery.of(context).size.width <= AppSizes.tabletBreakpoint)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md, vertical: AppSizes.sm),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setState(() => _showCart = false),
                    ),
                    Text(
                      '${AppStrings.cart} (${state.totalItems})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    if (state.isNotEmpty)
                      TextButton(
                        onPressed: () => context.read<CartCubit>().clearCart(),
                        child: const Text('Hapus Semua',
                            style: TextStyle(color: AppColors.error)),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: state.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined,
                              size: 48, color: AppColors.textHint),
                          SizedBox(height: AppSizes.sm),
                          Text(AppStrings.emptyCart,
                              style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: state.items.length,
                      itemBuilder: (context, index) {
                        return CartItemTile(item: state.items[index]);
                      },
                    ),
            ),
            _buildCartSummary(state),
          ],
        );
      },
    );
  }

  Widget _buildCartSummary(CartState state) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildSummaryRow(AppStrings.subtotal,
                CurrencyFormatter.format(state.subtotal)),
            if (state.totalDiscount > 0)
              _buildSummaryRow(
                AppStrings.discount,
                '- ${CurrencyFormatter.format(state.totalDiscount)}',
                valueColor: AppColors.error,
              ),
            _buildSummaryRow(
              '${AppStrings.tax} (${state.taxPercentage}%)',
              CurrencyFormatter.format(state.taxAmount),
            ),
            const Divider(height: AppSizes.md),
            _buildSummaryRow(
              AppStrings.total,
              CurrencyFormatter.format(state.totalAmountRounded),
              isBold: true,
              fontSize: 18,
            ),
            const SizedBox(height: AppSizes.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: state.isEmpty
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PaymentPage(),
                          ),
                        ),
                icon: const Icon(Icons.payment),
                label: Text(
                  '${AppStrings.payNow} - ${CurrencyFormatter.format(state.totalAmountRounded)}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
    double fontSize = 14,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: AppColors.textSecondary,
          )),
          Text(value, style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          )),
        ],
      ),
    );
  }
}
