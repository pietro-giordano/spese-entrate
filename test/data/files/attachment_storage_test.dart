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

  test('mimeTypeForName', () {
    expect(mimeTypeForName('a.jpeg'), 'image/jpeg');
    expect(mimeTypeForName('a.PNG'), 'image/png');
    expect(mimeTypeForName('fattura.pdf'), 'application/pdf');
    expect(mimeTypeForName('senza-estensione'), 'application/octet-stream');
  });
}
