import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spese_entrate/data/files/attachment_picker.dart';
import 'package:spese_entrate/data/files/attachment_storage.dart';

PickedAttachment bytesFile(String name, String content) =>
    PickedAttachment(name: name, mimeType: mimeTypeForName(name), openRead: () => Stream.value(utf8.encode(content)));

void main() {
  late Directory documents;
  late AttachmentStorage storage;

  setUp(() async {
    documents = await Directory.systemTemp.createTemp('spese_entrate_docs_');
    storage = AttachmentStorage(documentsDirectory: () async => documents);
  });
  tearDown(() => documents.delete(recursive: true));

  test('copia in attachments/<transaction_id>/<uuid>.<ext> con dimensione e sha256', () async {
    final attachment = await storage.store('tx-1', bytesFile('Scontrino.JPG', 'hello'));

    expect(attachment.transactionId, 'tx-1');
    expect(attachment.localPath, 'attachments/tx-1/${attachment.id}.jpg');
    expect(attachment.mimeType, 'image/jpeg');
    expect(attachment.sizeBytes, 5);
    // sha256("hello")
    expect(attachment.sha256, '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824');

    final file = File('${documents.path}/attachments/tx-1/${attachment.id}.jpg');
    expect(await file.readAsString(), 'hello');
    expect((await storage.fileFor(attachment)).path, file.path);
  });

  test('delete elimina i file e ignora quelli già assenti', () async {
    final attachment = await storage.store('tx-1', bytesFile('doc.pdf', '%PDF'));
    await storage.delete([attachment]);
    expect(await (await storage.fileFor(attachment)).exists(), isFalse);
    await storage.delete([attachment]);
  });

  test('copia interrotta a metà: nessun file parziale resta su disco', () async {
    final broken = PickedAttachment(
      name: 'foto.jpg',
      mimeType: 'image/jpeg',
      openRead: () async* {
        yield utf8.encode('inizio');
        throw const FileSystemException('lettura interrotta');
      },
    );
    await expectLater(storage.store('tx-1', broken), throwsA(isA<FileSystemException>()));
    expect(await storage.listFiles(), isEmpty);
  });

  test('check: ok, mancante, danneggiato (dimensione o contenuto diversi)', () async {
    final attachment = await storage.store('tx-1', bytesFile('doc.pdf', '%PDF-1.4'));
    expect(await storage.check(attachment), AttachmentFileStatus.ok);

    final file = await storage.fileFor(attachment);
    await file.writeAsString('%PDF-1.5'); // stessa lunghezza, contenuto diverso
    expect(await storage.check(attachment), AttachmentFileStatus.corrupted);
    await file.writeAsString('troncato');
    expect(await storage.check(attachment), AttachmentFileStatus.corrupted);

    await file.delete();
    expect(await storage.check(attachment), AttachmentFileStatus.missing);
  });

  test('listFiles: percorsi relativi con /, anche senza cartella', () async {
    expect(await storage.listFiles(), isEmpty);
    final a = await storage.store('tx-1', bytesFile('a.jpg', 'a'));
    final b = await storage.store('tx-2', bytesFile('b.pdf', 'b'));
    expect((await storage.listFiles()).map((f) => f.localPath), unorderedEquals([a.localPath, b.localPath]));
  });

  test('mimeTypeForName', () {
    expect(mimeTypeForName('a.jpeg'), 'image/jpeg');
    expect(mimeTypeForName('a.PNG'), 'image/png');
    expect(mimeTypeForName('fattura.pdf'), 'application/pdf');
    expect(mimeTypeForName('senza-estensione'), 'application/octet-stream');
  });
}
