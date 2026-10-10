import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/dates.dart';
import '../../../data/files/file_sharer.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/services/csv_export.dart';

part 'csv_exporter.g.dart';

/// Scrive il CSV in una cartella temporanea e apre la condivisione del telefono.
class CsvExporter {
  CsvExporter({required this._sharer, required this._directory});

  final FileSharer _sharer;
  final Future<Directory> Function() _directory;

  /// Nome del file con il periodo, es. `movimenti_2026-10-01_2026-10-31.csv`.
  static String fileName(DateRange range) => 'movimenti_${range.start}_${range.end}.csv';

  /// Restituisce il file scritto (utile ai test).
  Future<File> exportAndShare({
    required List<Transaction> transactions,
    required DateRange range,
    required Map<String, String> walletNames,
    required Map<String, String> categoryNames,
    required Map<String, String> labelNames,
  }) async {
    final csv = transactionsToCsv(
      transactions,
      walletNames: walletNames,
      categoryNames: categoryNames,
      labelNames: labelNames,
    );
    final file = File(p.join((await _directory()).path, fileName(range)));
    // UTF-8: il BOM all'inizio del testo diventa i byte EF BB BF che Excel riconosce.
    await file.writeAsString(csv, flush: true);
    await _sharer.shareFile(file.path, mimeType: 'text/csv', subject: 'Movimenti ${range.start} – ${range.end}');
    return file;
  }
}

@riverpod
CsvExporter csvExporter(Ref ref) =>
    CsvExporter(sharer: ref.watch(fileSharerProvider), directory: getTemporaryDirectory);
