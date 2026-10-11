import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/attachment.dart';
import '../../../domain/models/transaction.dart';

part 'transaction_detail_providers.g.dart';

/// Tutto ciò che serve a Modifica movimento.
class TransactionDetail {
  const TransactionDetail({
    required this.transaction,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  final Transaction transaction;
  final List<Attachment> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Movimento con allegati e date; null se non esiste o è stato cancellato.
@riverpod
Future<TransactionDetail?> transactionDetail(Ref ref, String id) async {
  final repository = ref.watch(transactionRepositoryProvider);
  final transaction = await repository.getById(id);
  if (transaction == null) return null;
  final timestamps = await repository.getTimestamps(id);
  return TransactionDetail(
    transaction: transaction,
    attachments: await repository.getAttachments(id),
    createdAt: timestamps!.createdAt,
    updatedAt: timestamps.updatedAt,
  );
}
