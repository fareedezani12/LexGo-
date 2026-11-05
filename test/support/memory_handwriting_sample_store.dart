import 'dart:typed_data';

import 'package:lexgo/models/handwriting_sample.dart';
import 'package:lexgo/services/handwriting_sample_store.dart';

class MemoryHandwritingSampleStore implements HandwritingSampleStore {
  final String? recognizedText;
  final Object? saveError;

  MemoryHandwritingSampleStore({this.recognizedText, this.saveError});

  final List<HandwritingSample> samples = [];
  final Map<String, Uint8List> images = {};
  final List<String> deletedIds = [];

  @override
  Future<List<HandwritingSample>> loadSamples() async =>
      List<HandwritingSample>.of(samples);

  @override
  Future<HandwritingSample> saveSample({
    required String title,
    required Uint8List imageBytes,
  }) async {
    if (saveError != null) throw saveError!;
    final sample = HandwritingSample(
      id: 'sample-${samples.length + 1}',
      title: title,
      createdAt: DateTime.now(),
      imagePath: 'memory://sample-${samples.length + 1}.png',
      recognizedText: recognizedText,
    );
    samples.insert(0, sample);
    images[sample.id] = imageBytes;
    return sample;
  }

  @override
  Future<Uint8List> loadImage(HandwritingSample sample) async {
    final image = images[sample.id];
    if (image == null) throw StateError('Image not found.');
    return image;
  }

  @override
  Future<void> deleteSample(HandwritingSample sample) async {
    samples.removeWhere((item) => item.id == sample.id);
    images.remove(sample.id);
    deletedIds.add(sample.id);
  }

  void addSample({
    required String id,
    required String title,
    required Uint8List imageBytes,
    String? recognizedText,
  }) {
    samples.add(
      HandwritingSample(
        id: id,
        title: title,
        createdAt: DateTime.utc(2026, 5, 12, 9, 30),
        imagePath: 'memory://$id.png',
        recognizedText: recognizedText,
      ),
    );
    images[id] = imageBytes;
  }
}
