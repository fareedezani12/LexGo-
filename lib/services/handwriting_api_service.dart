import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/handwriting_sample.dart';
import 'handwriting_sample_store.dart';

/// Connects the handwriting screens to the LexGo FastAPI endpoints.
///
/// Override the URL with --dart-define=LEXGO_API_BASE_URL=... when needed.
class HandwritingApiService implements HandwritingSampleStore {
  static const _configuredBaseUrl = String.fromEnvironment(
    'LEXGO_API_BASE_URL',
  );

  final http.Client _client;
  final bool _ownsClient;
  final String baseUrl;

  HandwritingApiService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _ownsClient = client == null,
      baseUrl = _normaliseBaseUrl(baseUrl ?? _defaultBaseUrl);

  static String get _defaultBaseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // Android emulators reach the host computer through this special IP.
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  static String _normaliseBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) throw ArgumentError('API base URL cannot be empty.');
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  @override
  Future<HandwritingSample> saveSample({
    required String title,
    required Uint8List imageBytes,
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      throw HandwritingApiException('Please enter a title for this sample.');
    }
    if (imageBytes.isEmpty) {
      throw HandwritingApiException('The handwriting image is empty.');
    }

    final request = http.MultipartRequest('POST', _uri('/samples/upload'))
      ..fields['title'] = cleanTitle
      ..files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'handwriting.png',
          contentType: http.MediaType('image', 'png'),
        ),
      );

    try {
      final streamedResponse = await _client
          .send(request)
          .timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamedResponse);
      _checkResponse(response);

      final body = _decodeObject(response.body);
      final id = body['sample_id'] ?? body['id'];
      final returnedTitle = body['title'];
      if (id == null || returnedTitle is! String) {
        throw const HandwritingApiException(
          'The server response did not include the saved sample details.',
        );
      }

      return HandwritingSample(
        id: id.toString(),
        title: returnedTitle,
        createdAt: _parseDate(body['created_at']) ?? DateTime.now(),
        imagePath: body['image_path']?.toString() ?? '',
        recognizedText: body['recognized_text'] is String
            ? body['recognized_text'] as String
            : null,
      );
    } on HandwritingApiException {
      rethrow;
    } on TimeoutException {
      throw const HandwritingApiException(
        'The upload took too long. Check your connection and try again.',
      );
    } catch (_) {
      throw const HandwritingApiException(
        'Could not connect to LexGo. Check that the backend is running and the browser allows this app to connect.',
      );
    }
  }

  @override
  Future<List<HandwritingSample>> loadSamples() async {
    try {
      final response = await _client
          .get(_uri('/samples'))
          .timeout(const Duration(seconds: 30));
      _checkResponse(response);

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const HandwritingApiException(
          'The server returned an unexpected samples response.',
        );
      }

      final samples = decoded.map((entry) {
        if (entry is! Map) {
          throw const HandwritingApiException(
            'The server returned an invalid sample record.',
          );
        }
        return HandwritingSample.fromJson(Map<String, dynamic>.from(entry));
      }).toList();
      samples.sort(
        (first, second) => second.createdAt.compareTo(first.createdAt),
      );
      return samples;
    } on HandwritingApiException {
      rethrow;
    } on TimeoutException {
      throw const HandwritingApiException(
        'Loading samples took too long. Please try again.',
      );
    } catch (_) {
      throw const HandwritingApiException(
        'Could not load samples. Check that the backend is running and the browser allows this app to connect.',
      );
    }
  }

  @override
  Future<Uint8List> loadImage(HandwritingSample sample) async {
    try {
      final response = await _client
          .get(sampleImageUri(sample))
          .timeout(const Duration(seconds: 30));
      _checkResponse(response);
      return response.bodyBytes;
    } on HandwritingApiException {
      rethrow;
    } on TimeoutException {
      throw const HandwritingApiException(
        'Loading this image took too long. Please try again.',
      );
    } catch (_) {
      throw const HandwritingApiException(
        'Could not load this image. Check your connection and try again.',
      );
    }
  }

  /// Builds the backend image route for Image.network or a direct link.
  Uri sampleImageUri(HandwritingSample sample) =>
      _uri('/samples/${Uri.encodeComponent(sample.id)}/image');

  @override
  Future<void> deleteSample(HandwritingSample sample) async {
    throw const HandwritingApiException(
      'Deleting samples is not available in the backend yet.',
    );
  }

  void close() {
    if (_ownsClient) _client.close();
  }

  static Map<String, dynamic> _decodeObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const HandwritingApiException(
        'The server returned an unexpected response.',
      );
    }
    return Map<String, dynamic>.from(decoded);
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  static void _checkResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    String message = 'The server could not complete the request.';
    try {
      final body = _decodeObject(response.body);
      final detail = body['detail'];
      if (detail is String && detail.isNotEmpty) message = detail;
    } catch (_) {
      // Keep the friendly default when the backend sends a non-JSON error.
    }
    throw HandwritingApiException(message);
  }
}

class HandwritingApiException implements Exception {
  final String message;

  const HandwritingApiException(this.message);

  @override
  String toString() => message;
}
