import 'dart:typed_data';

import '../models/handwriting_sample.dart';

/// Storage operations shared by the device repository and widget tests.
abstract interface class HandwritingSampleStore {
  Future<List<HandwritingSample>> loadSamples();

  Future<HandwritingSample> saveSample({
    required String title,
    required Uint8List imageBytes,
  });

  Future<Uint8List> loadImage(HandwritingSample sample);

  Future<void> deleteSample(HandwritingSample sample);
}
