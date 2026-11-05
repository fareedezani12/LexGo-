import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:lexgo/services/handwriting_api_service.dart';

void main() {
  test('uploads title and PNG as multipart form data', () async {
    late http.MultipartRequest multipartRequest;
    final client = _RecordingClient((request) async {
      multipartRequest = request as http.MultipartRequest;
      return _jsonResponse(
        200,
        jsonEncode({
          'message': 'Handwriting saved successfully!',
          'sample_id': 42,
          'title': 'Practice line',
          'image_path': 'uploads/handwriting/42.png',
          'recognized_text': 'The quick brown fox',
        }),
      );
    });
    final service = HandwritingApiService(
      client: client,
      baseUrl: 'http://localhost:8000/',
    );

    final sample = await service.saveSample(
      title: '  Practice line  ',
      imageBytes: Uint8List.fromList([137, 80, 78, 71]),
    );

    expect(multipartRequest.method, 'POST');
    expect(
      multipartRequest.url.toString(),
      'http://localhost:8000/samples/upload',
    );
    expect(multipartRequest.fields, {'title': 'Practice line'});
    expect(multipartRequest.files, hasLength(1));
    expect(multipartRequest.files.single.field, 'image');
    expect(multipartRequest.files.single.filename, 'handwriting.png');
    expect(multipartRequest.files.single.contentType.mimeType, 'image/png');
    expect(sample.id, '42');
    expect(sample.title, 'Practice line');
    expect(sample.recognizedText, 'The quick brown fox');
  });

  test('keeps empty recognition text when the backend returns no text', () async {
    final service = HandwritingApiService(
      client: _RecordingClient(
        (_) async => _jsonResponse(
          200,
          jsonEncode({
            'sample_id': 43,
            'title': 'Blank page',
            'image_path': 'uploads/handwriting/43.png',
            'recognized_text': '',
          }),
        ),
      ),
      baseUrl: 'http://localhost:8000',
    );

    final sample = await service.saveSample(
      title: 'Blank page',
      imageBytes: Uint8List.fromList([1]),
    );

    expect(sample.recognizedText, '');
  });

  test('loads samples and PNG images from the backend routes', () async {
    final requests = <http.BaseRequest>[];
    final client = _RecordingClient((request) async {
      requests.add(request);
      if (request.url.path == '/samples') {
        return _jsonResponse(
          200,
          jsonEncode([
            {
              'id': 7,
              'title': 'Saved sentence',
              'image_path': 'uploads/handwriting/seven.png',
              'created_at': '2026-11-02T10:30:00',
            },
          ]),
        );
      }
      return http.StreamedResponse(
        Stream<List<int>>.value([137, 80, 78, 71]),
        200,
        headers: {'content-type': 'image/png'},
      );
    });
    final service = HandwritingApiService(
      client: client,
      baseUrl: 'http://127.0.0.1:8000',
    );

    final samples = await service.loadSamples();
    final image = await service.loadImage(samples.single);

    expect(requests[0].url.path, '/samples');
    expect(requests[1].url.path, '/samples/7/image');
    expect(samples.single.id, '7');
    expect(samples.single.title, 'Saved sentence');
    expect(samples.single.createdAt, DateTime(2026, 11, 2, 10, 30));
    expect(image, [137, 80, 78, 71]);
  });

  test(
    'reports backend upload errors instead of treating them as success',
    () async {
      final service = HandwritingApiService(
        client: _RecordingClient(
          (_) async =>
              _jsonResponse(400, '{"detail":"Only PNG images are accepted."}'),
        ),
        baseUrl: 'http://localhost:8000',
      );

      await expectLater(
        service.saveSample(
          title: 'Sample',
          imageBytes: Uint8List.fromList([1]),
        ),
        throwsA(
          isA<HandwritingApiException>().having(
            (error) => error.message,
            'message',
            'Only PNG images are accepted.',
          ),
        ),
      );
    },
  );
}

http.StreamedResponse _jsonResponse(int statusCode, String body) {
  return http.StreamedResponse(
    Stream<List<int>>.value(utf8.encode(body)),
    statusCode,
    headers: {'content-type': 'application/json'},
  );
}

class _RecordingClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest request)
  responder;

  _RecordingClient(this.responder);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      responder(request);
}
