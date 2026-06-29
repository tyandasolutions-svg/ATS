import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/constants/app_colors.dart';
import 'package:flutter_pos/core/constants/app_sizes.dart';
import 'package:flutter_pos/core/constants/app_strings.dart';
import 'package:flutter_pos/core/widgets/empty_state_widget.dart';
import 'package:flutter_pos/core/widgets/shimmer_loading.dart';
import 'package:flutter_pos/features/products/presentation/cubit/product_cubit.dart';
import 'package:flutter_pos/features/products/presentation/widgets/product_card.dart';
import 'package:flutter_pos/features/products/presentation/widgets/category_chips.dart';
import 'package:flutter_pos/features/products/presentation/pages/product_form_page.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cubit = context.read<ProductCubit>();
    cubit.loadCategories();
    cubit.loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.products),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              // TODO: Open barcode scanner
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          const CategoryChips(),
          Expanded(child: _buildProductGrid()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductFormPage()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.md),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: AppStrings.searchProduct,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<ProductCubit>().searchProducts('');
                  },
                )
              : null,
        ),
        onChanged: (value) {
          context.read<ProductCubit>().searchProducts(value);
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
          return const ShimmerProductGrid();
        }
        if (state.products.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.inventory_2_outlined,
            title: 'Belum ada produk',
            subtitle: 'Tambahkan produk pertama Anda',
          );
        }
        return RefreshIndicator(
          onRefresh: () => context.read<ProductCubit>().loadProducts(),
          child: GridView.builder(
            padding: const EdgeInsets.all(AppSizes.md),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  MediaQuery.of(context).size.width > AppSizes.tabletBreakpoint
                      ? 4
                      : 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: AppSizes.sm,
              mainAxisSpacing: AppSizes.sm,
            ),
            itemCount: state.products.length,
            itemBuilder: (context, index) {
              return ProductCard(product: state.products[index]);
            },
          ),
        );
      },
    );
  }
}
