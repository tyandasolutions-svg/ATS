import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/constants/app_sizes.dart';
import 'package:flutter_pos/core/constants/app_strings.dart';
import 'package:flutter_pos/core/utils/helpers.dart';
import 'package:flutter_pos/core/utils/validators.dart';
import 'package:flutter_pos/core/widgets/app_snackbar.dart';
import 'package:flutter_pos/features/products/domain/entities/product_entity.dart';
import 'package:flutter_pos/features/products/presentation/cubit/product_cubit.dart';

class ProductFormPage extends StatefulWidget {
  final ProductEntity? product;

  const ProductFormPage({super.key, this.product});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _skuCtrl;
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _descCtrl;
  String? _selectedCategoryId;
  bool _trackStock = true;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _priceCtrl = TextEditingController(
        text: p != null ? p.price.toStringAsFixed(0) : '');
    _stockCtrl = TextEditingController(
        text: p != null ? p.stock.toString() : '0');
    _skuCtrl = TextEditingController(text: p?.sku ?? '');
    _barcodeCtrl = TextEditingController(text: p?.barcode ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _selectedCategoryId = p?.categoryId;
    _trackStock = p?.trackStock ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _skuCtrl.dispose();
    _barcodeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final product = ProductEntity(
      id: widget.product?.id ?? AppHelpers.generateId(),
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      sku: _skuCtrl.text.trim().isEmpty ? null : _skuCtrl.text.trim(),
      barcode:
          _barcodeCtrl.text.trim().isEmpty ? null : _barcodeCtrl.text.trim(),
      price: double.parse(_priceCtrl.text.replaceAll('.', '')),
      stock: int.parse(_stockCtrl.text),
      categoryId: _selectedCategoryId,
      trackStock: _trackStock,
      imagePath: widget.product?.imagePath,
    );

    final cubit = context.read<ProductCubit>();
    final success = _isEditing
        ? await cubit.updateProduct(product)
        : await cubit.createProduct(product);

    if (mounted && success) {
      AppSnackbar.showSuccess(
        context,
        _isEditing ? 'Produk berhasil diupdate' : 'Produk berhasil ditambah',
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? AppStrings.editProduct : AppStrings.addProduct),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.md),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Produk *'),
              validator: (v) => Validators.required(v, 'Nama produk'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSizes.md),
            TextFormField(
              controller: _priceCtrl,
              decoration: const InputDecoration(
                labelText: '${AppStrings.price} *',
                prefixText: 'Rp ',
              ),
              keyboardType: TextInputType.number,
              validator: Validators.price,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stockCtrl,
                    decoration:
                        const InputDecoration(labelText: AppStrings.stock),
                    keyboardType: TextInputType.number,
                    validator: Validators.stock,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Row(
                  children: [
                    const Text('Track Stok'),
                    Switch(
                      value: _trackStock,
                      onChanged: (v) => setState(() => _trackStock = v),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            BlocBuilder<ProductCubit, ProductState>(
              buildWhen: (prev, curr) => prev.categories != curr.categories,
              builder: (context, state) {
                return DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration:
                      const InputDecoration(labelText: AppStrings.category),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Tanpa Kategori'),
                    ),
                    ...state.categories.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                );
              },
            ),
            const SizedBox(height: AppSizes.md),
            TextFormField(
              controller: _skuCtrl,
              decoration: const InputDecoration(labelText: AppStrings.sku),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSizes.md),
            TextFormField(
              controller: _barcodeCtrl,
              decoration: InputDecoration(
                labelText: AppStrings.barcode,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () {
                    // TODO: Open scanner
                  },
                ),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSizes.md),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Deskripsi'),
              maxLines: 3,
            ),
            const SizedBox(height: AppSizes.xl),
            ElevatedButton(
              onPressed: _save,
              child: Text(_isEditing ? AppStrings.save : AppStrings.addProduct),
            ),
          ],
        ),
      ),
    );
  }
}
