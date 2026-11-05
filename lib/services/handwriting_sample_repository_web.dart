import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/handwriting_sample.dart';
import 'handwriting_sample_store.dart';

/// Stores web samples in IndexedDB instead of the browser's small localStorage.
/// The image and its metadata are saved together in one database record.
class HandwritingSampleRepository implements HandwritingSampleStore {
  static const _databaseName = 'lexgo_handwriting_samples.db';
  static const _legacyMetadataKey = 'lexgo.handwriting.samples';
  static const _legacyImageKeyPrefix = 'lexgo.handwriting.image.';

  static final _sampleStore = stringMapStoreFactory.store('samples');

  final DatabaseFactory _databaseFactory;
  final bool _migrateLegacyStorage;
  final SharedPreferencesAsync? _legacyPreferences;
  Future<Database>? _databaseFuture;

  HandwritingSampleRepository({DatabaseFactory? databaseFactoryForTesting})
    : _databaseFactory = databaseFactoryForTesting ?? databaseFactoryWeb,
      _migrateLegacyStorage = databaseFactoryForTesting == null,
      _legacyPreferences = databaseFactoryForTesting == null
          ? SharedPreferencesAsync()
          : null {
    debugPrint(
      '[LexGo web storage] Repository implementation initialized: '
      'HandwritingSampleRepository (web); '
      'factory=${_databaseFactory.runtimeType}; '
      'legacyMigration=$_migrateLegacyStorage.',
    );
  }

  Future<Database> _database() {
    return _databaseFuture ??= _openDatabase();
  }

  Future<Database> _openDatabase() async {
    debugPrint(
      '[LexGo web storage] Opening Sembast IndexedDB database '
      '"$_databaseName" using ${_databaseFactory.runtimeType}.',
    );
    try {
      final database = await _databaseFactory.openDatabase(_databaseName);
      debugPrint(
        '[LexGo web storage] Database open completed: '
        'name=${database.path}, version=${database.version}.',
      );
      return database;
    } catch (error, stackTrace) {
      _logFailure('Opening Sembast/IndexedDB database', error, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<HandwritingSample>> loadSamples() async {
    try {
      debugPrint('[LexGo web storage] Loading sample metadata.');
      final database = await _database();
      await _migrateLegacySamples(database);
      final records = await _sampleStore.find(database);
      final samples = records.map((record) {
        final data = record.value;
        return HandwritingSample.fromJson(
          Map<String, dynamic>.from(data['sample']! as Map),
        );
      }).toList();
      samples.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      debugPrint(
        '[LexGo web storage] Loaded ${samples.length} sample '
        'metadata record(s).',
      );
      return samples;
    } catch (error, stackTrace) {
      _logFailure('Loading sample metadata', error, stackTrace);
      rethrow;
    }
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

    final id = _newId();
    final sample = HandwritingSample(
      id: id,
      title: cleanTitle,
      createdAt: DateTime.now(),
      imagePath: 'indexeddb://$_databaseName/samples/$id',
    );
    final encodedImage = base64Encode(imageBytes);
    final record = <String, Object?>{
      'sample': sample.toJson(),
      'imageBase64': encodedImage,
    };

    try {
      debugPrint(
        '[LexGo web storage] Save started: id=$id, '
        'PNG bytes=${imageBytes.length}, '
        'Base64 characters=${encodedImage.length}.',
      );
      final metadataJson = jsonEncode(sample.toJson());
      final recordJson = jsonEncode(record);
      debugPrint(
        '[LexGo web storage] Serialization succeeded: '
        'metadataJson=${metadataJson.length} characters, '
        'completeRecordJson=${recordJson.length} characters.',
      );
      debugPrint('[LexGo web storage] Waiting for database initialization.');
      final database = await _database();
      debugPrint(
        '[LexGo web storage] Database ready; beginning Sembast put '
        'transaction for record $id.',
      );
      await _sampleStore.record(id).put(database, record);
      debugPrint(
        '[LexGo web storage] Sembast put transaction completed for '
        'record $id. Reading record back to verify both fields.',
      );
      final storedRecord = await _sampleStore.record(id).get(database);
      final storedSampleJson = storedRecord == null
          ? null
          : jsonEncode(storedRecord['sample']);
      final storedImage = storedRecord?['imageBase64'] as String?;
      if (storedRecord == null ||
          storedImage != encodedImage ||
          storedSampleJson != metadataJson) {
        throw StateError(
          'IndexedDB read-back verification failed: '
          'record=${storedRecord != null}, '
          'imageMatches=${storedImage == encodedImage}, '
          'metadataMatches=${storedSampleJson == metadataJson}.',
        );
      }
      final verifiedImageBytes = base64Decode(storedImage!);
      if (!_bytesEqual(verifiedImageBytes, imageBytes)) {
        throw StateError('IndexedDB image byte verification failed for $id.');
      }
      debugPrint(
        '[LexGo web storage] Save verified: record $id contains '
        'matching metadata and ${verifiedImageBytes.length} image bytes.',
      );
      return sample;
    } catch (error, stackTrace) {
      _logFailure(
        'Saving sample $id (PNG ${imageBytes.length} bytes; '
        'Base64 ${encodedImage.length} characters)',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<Uint8List> loadImage(HandwritingSample sample) async {
    try {
      debugPrint('[LexGo web storage] Loading image for ${sample.id}.');
      final database = await _database();
      await _migrateLegacySamples(database);
      final record = await _sampleStore.record(sample.id).get(database);
      final encodedImage = record?['imageBase64'] as String?;
      if (encodedImage == null) {
        throw StateError('The saved image could not be found.');
      }
      final bytes = Uint8List.fromList(base64Decode(encodedImage));
      debugPrint(
        '[LexGo web storage] Loaded ${bytes.length} image bytes '
        'for ${sample.id}.',
      );
      return bytes;
    } catch (error, stackTrace) {
      _logFailure('Loading image for sample ${sample.id}', error, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteSample(HandwritingSample sample) async {
    try {
      debugPrint('[LexGo web storage] Deleting record ${sample.id}.');
      final database = await _database();
      await _sampleStore.record(sample.id).delete(database);
      debugPrint('[LexGo web storage] Deleted record ${sample.id}.');
    } catch (error, stackTrace) {
      _logFailure('Deleting sample ${sample.id}', error, stackTrace);
      rethrow;
    }
  }

  /// Move samples saved by earlier versions from localStorage into IndexedDB.
  Future<void> _migrateLegacySamples(Database database) async {
    if (!_migrateLegacyStorage) return;
    final preferences = _legacyPreferences!;
    try {
      debugPrint('[LexGo web storage] Checking legacy localStorage samples.');
      final encodedMetadata = await preferences.getString(_legacyMetadataKey);
      if (encodedMetadata == null || encodedMetadata.isEmpty) {
        debugPrint('[LexGo web storage] No legacy sample metadata found.');
        return;
      }
      final decoded = jsonDecode(encodedMetadata) as List;
      debugPrint(
        '[LexGo web storage] Migrating ${decoded.length} legacy '
        'sample(s) into IndexedDB.',
      );
      for (final entry in decoded) {
        final sample = HandwritingSample.fromJson(
          Map<String, dynamic>.from(entry as Map),
        );
        if (await _sampleStore.record(sample.id).exists(database)) continue;
        final encodedImage = await preferences.getString(
          '$_legacyImageKeyPrefix${sample.id}',
        );
        if (encodedImage == null) {
          throw StateError('Legacy image for sample ${sample.id} is missing.');
        }
        await _sampleStore.record(sample.id).put(database, <String, Object?>{
          'sample': sample.toJson(),
          'imageBase64': encodedImage,
        });
      }
      // Remove legacy data only after every sample has been copied.
      for (final entry in decoded) {
        final sample = HandwritingSample.fromJson(
          Map<String, dynamic>.from(entry as Map),
        );
        await preferences.remove('$_legacyImageKeyPrefix${sample.id}');
      }
      await preferences.remove(_legacyMetadataKey);
      debugPrint('[LexGo web storage] Legacy migration completed.');
    } catch (error, stackTrace) {
      _logFailure('Migrating legacy localStorage samples', error, stackTrace);
      rethrow;
    }
  }

  static bool _bytesEqual(Uint8List first, Uint8List second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }

  static void _logFailure(String stage, Object error, StackTrace stackTrace) {
    debugPrint(
      '[LexGo web storage] FAILED at stage: $stage\n'
      'Original exception: $error\nOriginal stack trace:\n$stackTrace',
    );
  }

  String _newId() {
    final timePart = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final randomPart = Random.secure().nextInt(1 << 32).toRadixString(16);
    return '${timePart}_$randomPart';
  }
}
