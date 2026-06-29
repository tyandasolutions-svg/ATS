import 'package:drift/drift.dart';

// ==================== USERS ====================
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get email => text().nullable()();
  TextColumn get pin => text().withLength(min: 6, max: 6)();
  TextColumn get role => text().withDefault(const Constant('cashier'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get avatarPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ==================== CATEGORIES ====================
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get parentId => text().nullable().references(Categories, #id)();
  TextColumn get iconName => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ==================== PRODUCTS ====================
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  TextColumn get sku => text().nullable()();
  TextColumn get barcode => text().nullable()();
  RealColumn get price => real()();
  RealColumn get costPrice => real().withDefault(const Constant(0))();
  IntColumn get stock => integer().withDefault(const Constant(0))();
  TextColumn get categoryId =>
      text().nullable().references(Categories, #id)();
  TextColumn get imagePath => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get trackStock => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ==================== PRODUCT VARIANTS ====================
class ProductVariants extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  RealColumn get priceAdjustment => real().withDefault(const Constant(0))();
  IntColumn get stock => integer().withDefault(const Constant(0))();
  TextColumn get sku => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ==================== CUSTOMERS ====================
class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  IntColumn get loyaltyPoints => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ==================== TRANSACTIONS ====================
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get transactionNumber => text()();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get customerId =>
      text().nullable().references(Customers, #id)();
  RealColumn get subtotal => real()();
  RealColumn get discountAmount => real().withDefault(const Constant(0))();
  RealColumn get discountPercentage =>
      real().withDefault(const Constant(0))();
  RealColumn get taxAmount => real().withDefault(const Constant(0))();
  RealColumn get taxPercentage => real().withDefault(const Constant(0))();
  RealColumn get totalAmount => real()();
  RealColumn get paidAmount => real()();
  RealColumn get changeAmount => real().withDefault(const Constant(0))();
  TextColumn get status =>
      text().withDefault(const Constant('completed'))();
  TextColumn get note => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ==================== TRANSACTION ITEMS ====================
class TransactionItems extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId =>
      text().references(Transactions, #id)();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get variantId =>
      text().nullable().references(ProductVariants, #id)();
  TextColumn get productName => text()();
  IntColumn get quantity => integer()();
  RealColumn get unitPrice => real()();
  RealColumn get discountAmount => real().withDefault(const Constant(0))();
  RealColumn get totalPrice => real()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ==================== PAYMENT METHODS ====================
class PaymentMethods extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId =>
      text().references(Transactions, #id)();
  TextColumn get method => text()();
  RealColumn get amount => real()();
  TextColumn get reference => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ==================== HELD TRANSACTIONS ====================
class HeldTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get customerName => text().nullable()();
  TextColumn get note => text().nullable()();
  RealColumn get totalAmount => real()();
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ==================== HELD TRANSACTION ITEMS ====================
class HeldTransactionItems extends Table {
  TextColumn get id => text()();
  TextColumn get heldTransactionId =>
      text().references(HeldTransactions, #id)();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get variantId =>
      text().nullable().references(ProductVariants, #id)();
  TextColumn get productName => text()();
  IntColumn get quantity => integer()();
  RealColumn get unitPrice => real()();
  RealColumn get discountAmount => real().withDefault(const Constant(0))();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ==================== STORE SETTINGS ====================
class StoreSettings extends Table {
  TextColumn get id => text()();
  TextColumn get storeName => text().withDefault(const Constant('Toko Saya'))();
  TextColumn get storeAddress => text().nullable()();
  TextColumn get storePhone => text().nullable()();
  TextColumn get storeEmail => text().nullable()();
  TextColumn get logoPath => text().nullable()();
  RealColumn get taxPercentage => real().withDefault(const Constant(11.0))();
  TextColumn get receiptFooter => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
