import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lexgo/models/handwriting_sample.dart';
import 'package:lexgo/services/handwriting_sample_repository_web.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  late HandwritingSampleRepository repository;

  setUp(() {
    repository = HandwritingSampleRepository(
      databaseFactoryForTesting: newDatabaseFactoryMemory(),
    );
  });

  test('saves image and metadata together and loads both', () async {
    final imageBytes = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);

    final saved = await repository.saveSample(
      title: 'Edge sample',
      imageBytes: imageBytes,
    );

    expect(saved.id, isNotEmpty);
    expect(saved.imagePath, startsWith('indexeddb://'));
    expect((await repository.loadSamples()).single.title, 'Edge sample');
    expect(await repository.loadImage(saved), imageBytes);
  });

  test('deletes the metadata and stored image together', () async {
    final saved = await repository.saveSample(
      title: 'Delete me',
      imageBytes: Uint8List.fromList([1, 2, 3]),
    );

    await repository.deleteSample(saved);

    expect(await repository.loadSamples(), isEmpty);
    await expectLater(repository.loadImage(saved), throwsStateError);
  });

  test('rejects empty images and propagates missing image failures', () async {
    await expectLater(
      repository.saveSample(title: 'Empty', imageBytes: Uint8List(0)),
      throwsArgumentError,
    );
    await expectLater(
      repository.loadImage(
        HandwritingSample(
          id: 'missing',
          title: 'Missing',
          createdAt: DateTime.utc(2026, 1, 1),
          imagePath: 'indexeddb://missing',
        ),
      ),
      throwsStateError,
    );
  });
}
