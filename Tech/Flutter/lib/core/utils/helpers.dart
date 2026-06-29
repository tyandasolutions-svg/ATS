import 'package:uuid/uuid.dart';

abstract final class AppHelpers {
  static const _uuid = Uuid();

  static String generateId() => _uuid.v4();

  static String generateTransactionNumber() {
    final now = DateTime.now();
    final date =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final time =
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final random = now.millisecond.toString().padLeft(3, '0');
    return 'TRX-$date$time$random';
  }

  static String generateSku(String categoryCode, int sequence) {
    return '$categoryCode-${sequence.toString().padLeft(5, '0')}';
  }

  static double calculateDiscount({
    required double amount,
    required double discount,
    required bool isPercentage,
  }) {
    if (isPercentage) {
      return amount * (discount / 100);
    }
    return discount;
  }

  static double calculateTax(double amount, double taxPercentage) {
    return amount * (taxPercentage / 100);
  }

  static double calculateTotal({
    required double subtotal,
    required double discount,
    required double tax,
  }) {
    return subtotal - discount + tax;
  }

  static int calculateChange(int paid, int total) {
    return paid - total;
  }

  static bool isTablet(double width) => width >= 600;
}
