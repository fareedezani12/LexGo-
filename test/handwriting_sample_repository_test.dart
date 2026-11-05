import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lexgo/services/handwriting_sample_repository.dart';

void main() {
  test('samples and PNG images persist on disk and can be deleted', () async {
    final directory = await Directory.systemTemp.createTemp('lexgo_samples_');
    addTearDown(() => directory.delete(recursive: true));

    final imageBytes = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);
    final repository = HandwritingSampleRepository(
      storageRootForTesting: directory.path,
    );
    final saved = await repository.saveSample(
      title: 'My first sample',
      imageBytes: imageBytes,
    );

    expect(saved.id, isNotEmpty);
    expect(saved.title, 'My first sample');
    expect(saved.createdAt, isA<DateTime>());
    expect(await File(saved.imagePath).readAsBytes(), imageBytes);

    final metadataFile = File(
      '${directory.path}${Platform.pathSeparator}'
      'lexgo_handwriting_samples${Platform.pathSeparator}samples.json',
    );
    final metadata = jsonDecode(await metadataFile.readAsString()) as List;
    expect(metadata.single['id'], saved.id);
    expect(metadata.single['title'], saved.title);
    expect(metadata.single['createdAt'], saved.createdAt.toIso8601String());
    expect(metadata.single['imagePath'], saved.imagePath);

    final reopenedRepository = HandwritingSampleRepository(
      storageRootForTesting: directory.path,
    );
    final reopened = (await reopenedRepository.loadSamples()).single;
    expect(reopened.id, saved.id);
    expect(await reopenedRepository.loadImage(reopened), imageBytes);

    await reopenedRepository.deleteSample(reopened);
    expect(await File(saved.imagePath).exists(), isFalse);
    expect(await reopenedRepository.loadSamples(), isEmpty);
  });
}
