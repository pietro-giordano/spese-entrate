/// Esportazione dei movimenti in CSV per Excel in italiano.
library;

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../models/transaction.dart';
import 'csv_format.dart';

/// CSV con separatore `;`, BOM UTF-8 (così Excel riconosce gli accenti) e importi con la virgola.
/// I movimenti sono in ordine cronologico; le label sono separate da `|`.
/// Gli importi sono positivi, tranne le rettifiche che hanno segno: il tipo dice di che movimento si tratta.
String transactionsToCsv(
  Iterable<Transaction> transactions, {
  required Map<String, String> walletNames,
  required Map<String, String> categoryNames,
  required Map<String, String> labelNames,
}) {
  final dateFormat = DateFormat('dd/MM/yyyy');
  final sorted = transactions.toList()..sort((a, b) => a.date.compareTo(b.date));
  final rows = <List<String>>[
    csvHeaders,
    for (final tx in sorted)
      [
        dateFormat.format(tx.date.toDateTime()),
        csvTypeLabel(tx.type),
        formatCentsForSpreadsheet(tx.amountCents),
        tx.currency,
        walletNames[tx.walletId] ?? '',
        tx.toWalletId == null ? '' : (walletNames[tx.toWalletId] ?? ''),
        tx.categoryId == null ? '' : (categoryNames[tx.categoryId] ?? ''),
        tx.labelIds.map((id) => labelNames[id]).nonNulls.join(csvLabelSeparator),
        tx.note ?? '',
        tx.id,
      ],
  ];
  return const CsvEncoder(fieldDelimiter: ';', addBom: true).convert(rows);
}
