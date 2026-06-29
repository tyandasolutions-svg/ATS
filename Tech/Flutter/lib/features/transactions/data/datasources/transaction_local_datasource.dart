import 'package:drift/drift.dart';
import 'package:flutter_pos/core/database/app_database.dart';
import 'package:flutter_pos/core/errors/exceptions.dart';
import 'package:flutter_pos/core/utils/helpers.dart';
import 'package:flutter_pos/features/transactions/domain/entities/transaction_entity.dart';

abstract class TransactionLocalDataSource {
  Future<TransactionEntity> createTransaction(TransactionEntity transaction);
  Future<List<TransactionEntity>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    int limit,
    int offset,
  });
  Future<TransactionEntity> getTransactionById(String id);
  Future<void> voidTransaction(String id);
  Future<void> refundTransaction(String id);
  Future<Map<String, dynamic>> getDailySummary(DateTime date);
  Future<List<Map<String, dynamic>>> getBestSellingProducts({
    required DateTime startDate,
    required DateTime endDate,
    int limit,
  });
}

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  final AppDatabase _db;
  const TransactionLocalDataSourceImpl(this._db);

  @override
  Future<TransactionEntity> createTransaction(
      TransactionEntity transaction) async {
    try {
      return await _db.transaction(() async {
        // Insert transaction
        await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
              id: transaction.id,
              transactionNumber: transaction.transactionNumber,
              userId: transaction.userId,
              customerId: Value(transaction.customerId),
              subtotal: transaction.subtotal,
              discountAmount: Value(transaction.discountAmount),
              discountPercentage: Value(transaction.discountPercentage),
              taxAmount: Value(transaction.taxAmount),
              taxPercentage: Value(transaction.taxPercentage),
              totalAmount: transaction.totalAmount,
              paidAmount: transaction.paidAmount,
              changeAmount: Value(transaction.changeAmount),
              note: Value(transaction.note),
              createdAt: Value(DateTime.now()),
            ));

        // Insert items
        for (final item in transaction.items) {
          await _db.into(_db.transactionItems).insert(
                TransactionItemsCompanion.insert(
                  id: item.id,
                  transactionId: transaction.id,
                  productId: item.productId,
                  variantId: Value(item.variantId),
                  productName: item.productName,
                  quantity: item.quantity,
                  unitPrice: item.unitPrice,
                  discountAmount: Value(item.discountAmount),
                  totalPrice: item.totalPrice,
                  note: Value(item.note),
                ),
              );

          // Decrease stock
          final product = await (_db.select(_db.products)
                ..where((p) => p.id.equals(item.productId)))
              .getSingleOrNull();
          if (product != null && product.trackStock) {
            await (_db.update(_db.products)
                  ..where((p) => p.id.equals(item.productId)))
                .write(ProductsCompanion(
              stock: Value(product.stock - item.quantity),
            ));
          }
        }

        // Insert payment methods
        for (final payment in transaction.payments) {
          await _db.into(_db.paymentMethods).insert(
                PaymentMethodsCompanion.insert(
                  id: payment.id,
                  transactionId: transaction.id,
                  method: payment.method,
                  amount: payment.amount,
                  reference: Value(payment.reference),
                ),
              );
        }

        return transaction;
      });
    } catch (e) {
      throw DatabaseException(message: e.toString());
    }
  }

  @override
  Future<List<TransactionEntity>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final query = _db.select(_db.transactions)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
        ..limit(limit, offset: offset);

      if (startDate != null) {
        query.where((t) => t.createdAt.isBiggerOrEqualValue(startDate));
      }
      if (endDate != null) {
        query.where((t) => t.createdAt.isSmallerOrEqualValue(endDate));
      }
      if (status != null) {
        query.where((t) => t.status.equals(status));
      }

      final results = await query.get();
      final transactions = <TransactionEntity>[];

      for (final row in results) {
        final items = await _getTransactionItems(row.id);
        final payments = await _getPaymentMethods(row.id);
        transactions.add(TransactionEntity(
          id: row.id,
          transactionNumber: row.transactionNumber,
          userId: row.userId,
          customerId: row.customerId,
          subtotal: row.subtotal,
          discountAmount: row.discountAmount,
          discountPercentage: row.discountPercentage,
          taxAmount: row.taxAmount,
          taxPercentage: row.taxPercentage,
          totalAmount: row.totalAmount,
          paidAmount: row.paidAmount,
          changeAmount: row.changeAmount,
          status: row.status,
          note: row.note,
          isSynced: row.isSynced,
          items: items,
          payments: payments,
          createdAt: row.createdAt,
        ));
      }
      return transactions;
    } catch (e) {
      throw DatabaseException(message: e.toString());
    }
  }

  @override
  Future<TransactionEntity> getTransactionById(String id) async {
    try {
      final row = await (_db.select(_db.transactions)
            ..where((t) => t.id.equals(id)))
          .getSingle();
      final items = await _getTransactionItems(id);
      final payments = await _getPaymentMethods(id);

      return TransactionEntity(
        id: row.id,
        transactionNumber: row.transactionNumber,
        userId: row.userId,
        customerId: row.customerId,
        subtotal: row.subtotal,
        discountAmount: row.discountAmount,
        taxAmount: row.taxAmount,
        totalAmount: row.totalAmount,
        paidAmount: row.paidAmount,
        changeAmount: row.changeAmount,
        status: row.status,
        note: row.note,
        items: items,
        payments: payments,
        createdAt: row.createdAt,
      );
    } catch (e) {
      throw DatabaseException(message: e.toString());
    }
  }

  @override
  Future<void> voidTransaction(String id) async {
    try {
      await (_db.update(_db.transactions)..where((t) => t.id.equals(id)))
          .write(const TransactionsCompanion(
        status: Value('voided'),
        updatedAt: Value(null),
      ));
      // Restore stock
      final items = await _getTransactionItems(id);
      for (final item in items) {
        final product = await (_db.select(_db.products)
              ..where((p) => p.id.equals(item.productId)))
            .getSingleOrNull();
        if (product != null && product.trackStock) {
          await (_db.update(_db.products)
                ..where((p) => p.id.equals(item.productId)))
              .write(ProductsCompanion(
            stock: Value(product.stock + item.quantity),
          ));
        }
      }
    } catch (e) {
      throw DatabaseException(message: e.toString());
    }
  }

  @override
  Future<void> refundTransaction(String id) async {
    try {
      await (_db.update(_db.transactions)..where((t) => t.id.equals(id)))
          .write(const TransactionsCompanion(status: Value('refunded')));
    } catch (e) {
      throw DatabaseException(message: e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> getDailySummary(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final query = _db.select(_db.transactions)
        ..where((t) => t.createdAt.isBiggerOrEqualValue(startOfDay))
        ..where((t) => t.createdAt.isSmallerOrEqualValue(endOfDay))
        ..where((t) => t.status.equals('completed'));

      final results = await query.get();

      double totalSales = 0;
      int totalTransactions = results.length;
      int totalItems = 0;

      for (final tx in results) {
        totalSales += tx.totalAmount;
        final items = await (_db.select(_db.transactionItems)
              ..where((i) => i.transactionId.equals(tx.id)))
            .get();
        for (final item in items) {
          totalItems += item.quantity;
        }
      }

      return {
        'total_sales': totalSales,
        'total_transactions': totalTransactions,
        'total_items': totalItems,
        'average_transaction':
            totalTransactions > 0 ? totalSales / totalTransactions : 0.0,
      };
    } catch (e) {
      throw DatabaseException(message: e.toString());
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getBestSellingProducts({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    try {
      // Get all completed transaction IDs in range
      final txQuery = _db.select(_db.transactions)
        ..where((t) => t.createdAt.isBiggerOrEqualValue(startDate))
        ..where((t) => t.createdAt.isSmallerOrEqualValue(endDate))
        ..where((t) => t.status.equals('completed'));

      final transactions = await txQuery.get();
      final txIds = transactions.map((t) => t.id).toList();

      if (txIds.isEmpty) return [];

      // Aggregate items
      final Map<String, Map<String, dynamic>> productSales = {};

      for (final txId in txIds) {
        final items = await (_db.select(_db.transactionItems)
              ..where((i) => i.transactionId.equals(txId)))
            .get();
        for (final item in items) {
          if (productSales.containsKey(item.productId)) {
            productSales[item.productId]!['quantity'] += item.quantity;
            productSales[item.productId]!['total'] += item.totalPrice;
          } else {
            productSales[item.productId] = {
              'product_id': item.productId,
              'product_name': item.productName,
              'quantity': item.quantity,
              'total': item.totalPrice,
            };
          }
        }
      }

      final sorted = productSales.values.toList()
        ..sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));

      return sorted.take(limit).toList();
    } catch (e) {
      throw DatabaseException(message: e.toString());
    }
  }

  Future<List<TransactionItemEntity>> _getTransactionItems(
      String transactionId) async {
    final items = await (_db.select(_db.transactionItems)
          ..where((i) => i.transactionId.equals(transactionId)))
        .get();
    return items
        .map((i) => TransactionItemEntity(
              id: i.id,
              transactionId: i.transactionId,
              productId: i.productId,
              variantId: i.variantId,
              productName: i.productName,
              quantity: i.quantity,
              unitPrice: i.unitPrice,
              discountAmount: i.discountAmount,
              totalPrice: i.totalPrice,
              note: i.note,
            ))
        .toList();
  }

  Future<List<PaymentMethodEntity>> _getPaymentMethods(
      String transactionId) async {
    final payments = await (_db.select(_db.paymentMethods)
          ..where((p) => p.transactionId.equals(transactionId)))
        .get();
    return payments
        .map((p) => PaymentMethodEntity(
              id: p.id,
              transactionId: p.transactionId,
              method: p.method,
              amount: p.amount,
              reference: p.reference,
            ))
        .toList();
  }
}
