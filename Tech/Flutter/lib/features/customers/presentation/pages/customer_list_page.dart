import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_pos/features/customers/domain/entities/customer_entity.dart';
import 'package:flutter_pos/features/customers/domain/repositories/customer_repository.dart';
import 'package:flutter_pos/core/constants/app_colors.dart';
import 'package:flutter_pos/core/constants/app_sizes.dart';
import 'package:flutter_pos/core/utils/helpers.dart';
import 'package:flutter_pos/core/utils/validators.dart';
import 'package:flutter_pos/core/widgets/app_snackbar.dart';
import 'package:flutter_pos/core/widgets/empty_state_widget.dart';

// ========================= CUBIT =========================
part 'customer_state.dart';

class CustomerCubit extends Cubit<CustomerListState> {
  final CustomerRepository _repository;

  CustomerCubit({required CustomerRepository repository})
      : _repository = repository,
        super(const CustomerListState());

  Future<void> loadCustomers({String? query}) async {
    emit(state.copyWith(status: CustomerStatus.loading));
    final result = await _repository.getCustomers(searchQuery: query);
    result.fold(
      (f) => emit(state.copyWith(
          status: CustomerStatus.error, errorMessage: f.message)),
      (customers) => emit(
          state.copyWith(status: CustomerStatus.loaded, customers: customers)),
    );
  }

  Future<bool> createCustomer(CustomerEntity customer) async {
    final result = await _repository.createCustomer(customer);
    return result.fold((_) => false, (_) {
      loadCustomers();
      return true;
    });
  }

  Future<bool> updateCustomer(CustomerEntity customer) async {
    final result = await _repository.updateCustomer(customer);
    return result.fold((_) => false, (_) {
      loadCustomers();
      return true;
    });
  }

  Future<bool> deleteCustomer(String id) async {
    final result = await _repository.deleteCustomer(id);
    return result.fold((_) => false, (_) {
      loadCustomers();
      return true;
    });
  }
}

// ========================= PAGE =========================
class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CustomerCubit>().loadCustomers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pelanggan')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Cari pelanggan...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) =>
                  context.read<CustomerCubit>().loadCustomers(query: v),
            ),
          ),
          Expanded(
            child: BlocBuilder<CustomerCubit, CustomerListState>(
              builder: (context, state) {
                if (state.status == CustomerStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.customers.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.people_outline,
                    title: 'Belum ada pelanggan',
                  );
                }
                return ListView.builder(
                  itemCount: state.customers.length,
                  itemBuilder: (context, index) {
                    final c = state.customers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(c.name[0].toUpperCase(),
                            style: const TextStyle(color: AppColors.primary)),
                      ),
                      title: Text(c.name),
                      subtitle: Text(c.phone ?? '-'),
                      trailing: Text(
                        '${c.loyaltyPoints} poin',
                        style: const TextStyle(
                            color: AppColors.secondary, fontSize: 12),
                      ),
                      onTap: () => _showCustomerForm(context, customer: c),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCustomerForm(context),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  void _showCustomerForm(BuildContext context, {CustomerEntity? customer}) {
    final nameCtrl = TextEditingController(text: customer?.name ?? '');
    final phoneCtrl = TextEditingController(text: customer?.phone ?? '');
    final emailCtrl = TextEditingController(text: customer?.email ?? '');
    final addressCtrl = TextEditingController(text: customer?.address ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: AppSizes.md,
          right: AppSizes.md,
          top: AppSizes.md,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                customer != null ? 'Edit Pelanggan' : 'Tambah Pelanggan',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSizes.md),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama *'),
                validator: (v) => Validators.required(v, 'Nama'),
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'No. Telepon'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Alamat'),
              ),
              const SizedBox(height: AppSizes.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final entity = CustomerEntity(
                      id: customer?.id ?? AppHelpers.generateId(),
                      name: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim().isEmpty
                          ? null
                          : phoneCtrl.text.trim(),
                      email: emailCtrl.text.trim().isEmpty
                          ? null
                          : emailCtrl.text.trim(),
                      address: addressCtrl.text.trim().isEmpty
                          ? null
                          : addressCtrl.text.trim(),
                      loyaltyPoints: customer?.loyaltyPoints ?? 0,
                    );
                    final cubit = context.read<CustomerCubit>();
                    final success = customer != null
                        ? await cubit.updateCustomer(entity)
                        : await cubit.createCustomer(entity);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted && success) {
                      AppSnackbar.showSuccess(context, 'Berhasil disimpan');
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ),
              const SizedBox(height: AppSizes.md),
            ],
          ),
        ),
      ),
    );
  }
}
