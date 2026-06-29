import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p; // ignore: depend_on_referenced_packages
import 'package:flutter_pos/core/database/tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Users,
  Categories,
  Products,
  ProductVariants,
  Customers,
  Transactions,
  TransactionItems,
  PaymentMethods,
  HeldTransactions,
  HeldTransactionItems,
  StoreSettings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _seedData();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle future migrations here
      },
    );
  }

  Future<void> _seedData() async {
    // Insert default admin user
    await into(users).insert(UsersCompanion.insert(
      id: 'admin-001',
      name: 'Admin',
      email: const Value('admin@pos.com'),
      pin: '123456',
      role: const Value('admin'),
      isActive: const Value(true),
      createdAt: Value(DateTime.now()),
    ));

    // Insert default store settings
    await into(storeSettings).insert(StoreSettingsCompanion.insert(
      id: 'store-001',
      storeName: const Value('Toko Saya'),
      taxPercentage: const Value(11.0),
      createdAt: Value(DateTime.now()),
    ));

    // Insert default categories
    final defaultCategories = [
      'Makanan',
      'Minuman',
      'Snack',
      'Lainnya',
    ];
    for (var i = 0; i < defaultCategories.length; i++) {
      await into(categories).insert(CategoriesCompanion.insert(
        id: 'cat-${i + 1}',
        name: defaultCategories[i],
        createdAt: Value(DateTime.now()),
      ));
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'flutter_pos.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
