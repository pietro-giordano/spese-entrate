import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:spese_entrate/core/clock.dart';
import 'package:spese_entrate/core/dates.dart';
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:spese_entrate/data/db/database_provider.dart';
import 'package:spese_entrate/data/files/attachment_picker.dart';
import 'package:spese_entrate/data/files/attachment_storage.dart';
import 'package:spese_entrate/data/repositories/drift_transaction_repository.dart';
import 'package:spese_entrate/data/repositories/repository_providers.dart';
import 'package:spese_entrate/domain/models/attachment.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/domain/models/wallet.dart';
import 'package:spese_entrate/features/transactions/application/quick_add_controller.dart';

PickedAttachment pdf(String name) =>
    PickedAttachment(name: name, mimeType: 'application/pdf', openRead: () => Stream.value(utf8.encode('%PDF-$name')));

/// Repository che salva i file ma fallisce sulla scrittura nel database.
class FailingTransactionRepository extends DriftTransactionRepository {
  FailingTransactionRepository(super.db);

  @override
  Future<void> save(Transaction transaction, {List<Attachment> attachments = const []}) =>
      Future.error(StateError('database non disponibile'));
}

void main() {
  group('resolveTransferWallets', () {
    Wallet wallet(String id, {bool archived = false}) => Wallet(
      id: id,
      name: id,
      type: WalletType.cash,
      initialBalanceDate: LocalDate(2026, 1, 1),
      archivedAt: archived ? DateTime.utc(2026) : null,
    );
    final wallets = [wallet('cc'), wallet('cash'), wallet('card'), wallet('old', archived: true)];

    test('origine dal predefinito, destinazione il primo portafoglio diverso', () {
      final result = resolveTransferWallets(chosenFrom: null, chosenTo: null, defaultFromId: 'cash', wallets: wallets);
      expect((result.from, result.to), ('cash', 'cc'));
    });

    test('rispetta le scelte, ma mai due volte lo stesso portafoglio', () {
      expect(resolveTransferWallets(chosenFrom: 'card', chosenTo: 'cash', defaultFromId: 'cc', wallets: wallets), (
        from: 'card',
        to: 'cash',
      ));
      expect(resolveTransferWallets(chosenFrom: 'cc', chosenTo: 'cc', defaultFromId: 'cc', wallets: wallets), (
        from: 'cc',
        to: 'cash',
      ));
    });

    test('con un solo portafoglio la destinazione è null', () {
      expect(resolveTransferWallets(chosenFrom: null, chosenTo: null, defaultFromId: null, wallets: [wallet('cc')]), (
        from: 'cc',
        to: null,
      ));
    });
  });

  group('QuickAddController', () {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    late ProviderContainer container;
    late AppDatabase db;
    late Directory documents;

    ProviderContainer makeContainer(TransactionType type, {List<Override> extra = const []}) {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => DateTime(2026, 10, 10, 9)),
          attachmentStorageProvider.overrideWithValue(AttachmentStorage(documentsDirectory: () async => documents)),
          ...extra,
        ],
      );
      container.listen(quickAddControllerProvider(type), (_, _) {});
      addTearDown(container.dispose);
      return container;
    }

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory(), now: () => DateTime.utc(2026, 10, 10, 8));
      documents = await Directory.systemTemp.createTemp('spese_entrate_docs_');
      addTearDown(() async {
        await db.close();
        await documents.delete(recursive: true);
      });
    });

    group('trasferimento', () {
      final provider = quickAddControllerProvider(TransactionType.transfer);
      setUp(() => container = makeContainer(TransactionType.transfer));
      QuickAddController controller() => container.read(provider.notifier);

      test('non serve la categoria', () {
        expect(container.read(provider).isCategoryMissing, isFalse);
      });

      test('portafogli uguali o mancanti non sono validi', () async {
        controller().pressKey('5');
        expect(await controller().save(walletId: 'cc', toWalletId: 'cc'), isNull);
        expect(await controller().save(walletId: 'cc'), isNull);
        expect(container.read(provider).showErrors, isTrue);
        expect(await container.read(transactionRepositoryProvider).watchAll().first, isEmpty);
      });

      test('salva origine e destinazione, senza categoria né label', () async {
        controller()
          ..setType(TransactionType.expense)
          ..selectCategory('groceries')
          ..toggleLabel('home')
          ..setType(TransactionType.transfer)
          ..pressKey('5')
          ..pressKey('00');

        final saved = await controller().save(walletId: 'cc', toWalletId: 'cash');
        final stored = (await container.read(transactionRepositoryProvider).watchAll().first).single;
        expect(stored.id, saved!.id);
        expect(stored.type, TransactionType.transfer);
        expect(stored.amountCents, 500);
        expect((stored.walletId, stored.toWalletId), ('cc', 'cash'));
        expect(stored.categoryId, isNull);
        expect(stored.labelIds, isEmpty);
      });

      test('scegliere come origine l\'attuale destinazione scambia i due', () {
        controller().chooseTransferSource('cash', from: 'cc', to: 'cash');
        expect((container.read(provider).fromWalletId, container.read(provider).toWalletId), ('cash', 'cc'));

        controller().chooseTransferDestination('cash', from: 'cash', to: 'cc');
        expect((container.read(provider).fromWalletId, container.read(provider).toWalletId), ('cc', 'cash'));

        controller().swapTransferWallets(from: 'cc', to: 'cash');
        expect((container.read(provider).fromWalletId, container.read(provider).toWalletId), ('cash', 'cc'));
      });
    });

    group('allegati', () {
      final provider = quickAddControllerProvider(TransactionType.expense);
      QuickAddController controller() => container.read(provider.notifier);

      test('al massimo 5', () {
        container = makeContainer(TransactionType.expense);
        for (var i = 0; i < maxAttachments; i++) {
          expect(controller().addAttachment(pdf('$i.pdf')), isTrue);
        }
        expect(controller().addAttachment(pdf('troppi.pdf')), isFalse);
        expect(container.read(provider).attachments, hasLength(maxAttachments));

        controller().removeAttachment(container.read(provider).attachments.first);
        expect(container.read(provider).canAddAttachment, isTrue);
      });

      test('al salvataggio copia i file e scrive gli allegati con il movimento', () async {
        container = makeContainer(TransactionType.expense);
        controller()
          ..pressKey('9')
          ..selectCategory('groceries')
          ..addAttachment(pdf('scontrino.pdf'))
          ..addAttachment(pdf('garanzia.pdf'));

        final saved = await controller().save(walletId: 'cc');
        final attachments = await container.read(transactionRepositoryProvider).getAttachments(saved!.id);
        expect(attachments, hasLength(2));
        for (final attachment in attachments) {
          expect(attachment.localPath, startsWith('attachments/${saved.id}/'));
          expect(attachment.localPath, endsWith('.pdf'));
          expect(await File('${documents.path}/${attachment.localPath}').exists(), isTrue);
        }

        final outbox = await db.select(db.outbox).get();
        expect(outbox.where((o) => o.entity == 'attachments'), hasLength(2));
      });

      test('se il database fallisce, i file copiati vengono eliminati', () async {
        container = makeContainer(
          TransactionType.expense,
          extra: [transactionRepositoryProvider.overrideWithValue(FailingTransactionRepository(db))],
        );
        controller()
          ..pressKey('9')
          ..selectCategory('groceries')
          ..addAttachment(pdf('scontrino.pdf'));

        await expectLater(controller().save(walletId: 'cc'), throwsStateError);
        final attachmentsDir = Directory('${documents.path}/attachments');
        final leftovers = await attachmentsDir.exists()
            ? await attachmentsDir.list(recursive: true).where((e) => e is File).toList()
            : <FileSystemEntity>[];
        expect(leftovers, isEmpty);
        expect(container.read(provider).saving, isFalse);
      });
    });
  });
}
