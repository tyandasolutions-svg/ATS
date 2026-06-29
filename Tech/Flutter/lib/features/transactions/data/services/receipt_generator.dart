import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter_pos/core/utils/currency_formatter.dart';
import 'package:flutter_pos/core/utils/date_formatter.dart';
import 'package:flutter_pos/features/transactions/domain/entities/transaction_entity.dart';

class ReceiptGenerator {
  final String storeName;
  final String? storeAddress;
  final String? storePhone;
  final String? receiptFooter;

  const ReceiptGenerator({
    required this.storeName,
    this.storeAddress,
    this.storePhone,
    this.receiptFooter,
  });

  Future<pw.Document> generateReceipt(TransactionEntity transaction) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity,
            marginAll: 5 * PdfPageFormat.mm),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              _buildHeader(),
              pw.SizedBox(height: 8),
              _buildDivider(),
              _buildTransactionInfo(transaction),
              _buildDivider(),
              _buildItems(transaction),
              _buildDivider(),
              _buildSummary(transaction),
              _buildDivider(),
              _buildPaymentInfo(transaction),
              pw.SizedBox(height: 12),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  Future<void> printReceipt(TransactionEntity transaction) async {
    final pdf = await generateReceipt(transaction);
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  Future<void> shareReceipt(TransactionEntity transaction) async {
    final pdf = await generateReceipt(transaction);
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'struk_${transaction.transactionNumber}.pdf',
    );
  }

  pw.Widget _buildHeader() {
    return pw.Column(
      children: [
        pw.Text(
          storeName,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        if (storeAddress != null)
          pw.Text(storeAddress!, style: const pw.TextStyle(fontSize: 9)),
        if (storePhone != null)
          pw.Text('Tel: $storePhone', style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  pw.Widget _buildDivider() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Divider(thickness: 0.5),
    );
  }

  pw.Widget _buildTransactionInfo(TransactionEntity tx) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _infoRow('No', tx.transactionNumber),
        _infoRow(
          'Tanggal',
          tx.createdAt != null ? DateFormatter.formatDateTime(tx.createdAt!) : '-',
        ),
        if (tx.customerName != null) _infoRow('Pelanggan', tx.customerName!),
      ],
    );
  }

  pw.Widget _buildItems(TransactionEntity tx) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: tx.items.map((item) {
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(item.productName, style: const pw.TextStyle(fontSize: 9)),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '  ${item.quantity} x ${CurrencyFormatter.format(item.unitPrice)}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    CurrencyFormatter.format(item.totalPrice),
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
              if (item.discountAmount > 0)
                pw.Text(
                  '  Diskon: -${CurrencyFormatter.format(item.discountAmount)}',
                  style: const pw.TextStyle(fontSize: 8),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _buildSummary(TransactionEntity tx) {
    return pw.Column(
      children: [
        _summaryRow('Subtotal', CurrencyFormatter.format(tx.subtotal)),
        if (tx.discountAmount > 0)
          _summaryRow(
              'Diskon', '-${CurrencyFormatter.format(tx.discountAmount)}'),
        if (tx.taxAmount > 0)
          _summaryRow(
              'PPN (${tx.taxPercentage}%)', CurrencyFormatter.format(tx.taxAmount)),
        pw.SizedBox(height: 4),
        _summaryRow('TOTAL', CurrencyFormatter.format(tx.totalAmount),
            bold: true),
        _summaryRow('Bayar', CurrencyFormatter.format(tx.paidAmount)),
        if (tx.changeAmount > 0)
          _summaryRow('Kembali', CurrencyFormatter.format(tx.changeAmount)),
      ],
    );
  }

  pw.Widget _buildPaymentInfo(TransactionEntity tx) {
    if (tx.payments.isEmpty) return pw.SizedBox.shrink();
    return pw.Column(
      children: tx.payments.map((p) {
        final label = switch (p.method) {
          'cash' => 'Tunai',
          'qris' => 'QRIS',
          'transfer' => 'Transfer',
          'ewallet' => 'E-Wallet',
          'card' => 'Kartu',
          _ => p.method,
        };
        return _summaryRow(label, CurrencyFormatter.format(p.amount));
      }).toList(),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Text(
          receiptFooter ?? 'Terima kasih atas kunjungan Anda!',
          style: const pw.TextStyle(fontSize: 9),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Powered by Flutter POS',
          style: const pw.TextStyle(fontSize: 7),
        ),
      ],
    );
  }

  pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('$label:', style: const pw.TextStyle(fontSize: 8)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  pw.Widget _summaryRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: bold ? 10 : 9,
                  fontWeight: bold ? pw.FontWeight.bold : null)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: bold ? 10 : 9,
                  fontWeight: bold ? pw.FontWeight.bold : null)),
        ],
      ),
    );
  }
}
