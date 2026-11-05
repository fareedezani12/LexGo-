import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../models/handwriting_sample.dart';
import 'handwriting_sample_store.dart';

/// Stores PNG files and a JSON index in the app's private documents folder.
class HandwritingSampleRepository implements HandwritingSampleStore {
  final String? storageRootForTesting;

  HandwritingSampleRepository({this.storageRootForTesting});

  Future<Directory> _sampleDirectory() async {
    final root = storageRootForTesting == null
        ? await getApplicationDocumentsDirectory()
        : Directory(storageRootForTesting!);
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}lexgo_handwriting_samples',
    );
    await directory.create(recursive: true);
    return directory;
  }

  Future<File> _metadataFile() async {
    final directory = await _sampleDirectory();
    return File('${directory.path}${Platform.pathSeparator}samples.json');
  }

  @override
  Future<List<HandwritingSample>> loadSamples() async {
    final metadataFile = await _metadataFile();
    if (!await metadataFile.exists()) return [];

    final decoded = jsonDecode(await metadataFile.readAsString()) as List;
    final samples = decoded
        .map(
          (entry) => HandwritingSample.fromJson(
            Map<String, dynamic>.from(entry as Map),
          ),
        )
        .toList();
    samples.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return samples;
  }

  @override
  Future<HandwritingSample> saveSample({
    required String title,
    required Uint8List imageBytes,
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'A sample title is required.');
    }
    if (imageBytes.isEmpty) {
      throw ArgumentError.value(
        imageBytes,
        'imageBytes',
        'Image cannot be empty.',
      );
    }

    final directory = await _sampleDirectory();
    final id = _newId();
    final imageFile = File('${directory.path}${Platform.pathSeparator}$id.png');
    final sample = HandwritingSample(
      id: id,
      title: cleanTitle,
      createdAt: DateTime.now(),
      imagePath: imageFile.path,
    );

    await imageFile.writeAsBytes(imageBytes, flush: true);
    try {
      final samples = await loadSamples();
      await _writeSamples([sample, ...samples]);
    } catch (_) {
      if (await imageFile.exists()) await imageFile.delete();
      rethrow;
    }
    return sample;
  }

  @override
  Future<Uint8List> loadImage(HandwritingSample sample) async {
    return File(sample.imagePath).readAsBytes();
  }

  @override
  Future<void> deleteSample(HandwritingSample sample) async {
    final imageFile = File(sample.imagePath);
    if (await imageFile.exists()) await imageFile.delete();

    final samples = await loadSamples();
    await _writeSamples(samples.where((item) => item.id != sample.id).toList());
  }

  Future<void> _writeSamples(List<HandwritingSample> samples) async {
    final metadataFile = await _metadataFile();
    final temporaryFile = File('${metadataFile.path}.tmp');
    await temporaryFile.writeAsString(
      jsonEncode(samples.map((sample) => sample.toJson()).toList()),
      flush: true,
    );
    if (await metadataFile.exists()) await metadataFile.delete();
    await temporaryFile.rename(metadataFile.path);
  }

  String _newId() {
    final timePart = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final randomPart = Random.secure().nextInt(1 << 32).toRadixString(16);
    return '${timePart}_$randomPart';
  }
}
