import 'dart:typed_data';

import '../models/handwriting_sample.dart';
import 'handwriting_sample_store.dart';

/// Fallback for targets without a local sample storage implementation.
class HandwritingSampleRepository implements HandwritingSampleStore {
  HandwritingSampleRepository({String? storageRootForTesting});

  @override
  Future<List<HandwritingSample>> loadSamples() async =>
      throw UnsupportedError('Local handwriting storage is not supported.');

  @override
  Future<HandwritingSample> saveSample({
    required String title,
    required Uint8List imageBytes,
  }) async =>
      throw UnsupportedError('Local handwriting storage is not supported.');

  @override
  Future<Uint8List> loadImage(HandwritingSample sample) async =>
      throw UnsupportedError('Local handwriting storage is not supported.');

  @override
  Future<void> deleteSample(HandwritingSample sample) async =>
      throw UnsupportedError('Local handwriting storage is not supported.');
}
