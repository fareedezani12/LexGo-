import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexgo/handwriting_screen.dart';
import 'package:lexgo/main.dart';
import 'package:lexgo/models/handwriting_sample.dart';
import 'package:lexgo/my_writing_screen.dart';
import 'package:lexgo/services/handwriting_api_service.dart';

import 'support/memory_handwriting_sample_store.dart';

final Uint8List _tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/f0cAAAAASUVORK5CYII=',
);

void main() {
  testWidgets('Submit uploads the PNG and displays recognition result', (
    tester,
  ) async {
    final repository = MemoryHandwritingSampleStore(
      recognizedText: 'Practice makes progress.',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HandwritingScreen(
          repository: repository,
          imageExporter: () async => _tinyPng,
        ),
      ),
    );

    await _drawWriting(tester);
    await tester.tap(find.byKey(const ValueKey('submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Writing preview'), findsOneWidget);
    expect(
      find.text('Submit this PNG to save it and recognize the handwriting.'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('sample_title_field')),
      'My first sentence',
    );
    await tester.tap(find.byKey(const ValueKey('save_sample_button')));
    await tester.pumpAndSettle();

    expect(repository.samples, hasLength(1));
    expect(repository.samples.single.title, 'My first sentence');
    expect(repository.images.values.single, isNotEmpty);
    expect(repository.images.values.single.take(8), [
      137,
      80,
      78,
      71,
      13,
      10,
      26,
      10,
    ]);
    expect(
      find.text('Upload and recognition completed successfully.'),
      findsOneWidget,
    );
    expect(find.text('My first sentence'), findsOneWidget);
    expect(find.text('Practice makes progress.'), findsOneWidget);
    expect(find.byKey(const ValueKey('canvas_result_image')), findsOneWidget);
  });

  testWidgets('save shows progress and confirms only after upload succeeds', (
    tester,
  ) async {
    final repository = _PendingUploadStore();
    await tester.pumpWidget(
      MaterialApp(
        home: HandwritingScreen(
          repository: repository,
          imageExporter: () async => _tinyPng,
        ),
      ),
    );

    await _drawWriting(tester);
    await tester.tap(find.byKey(const ValueKey('submit_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save_sample_button')));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
    expect(
      find.text('Uploading image and recognizing handwriting…'),
      findsOneWidget,
    );

    repository.upload.complete(
      HandwritingSample(
        id: 'pending-1',
        title: 'Practice',
        createdAt: DateTime.now(),
        imagePath: 'uploads/pending.png',
        recognizedText: 'Recognized from the canvas',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recognized from the canvas'), findsOneWidget);
  });

  testWidgets('empty recognition text has a helpful result message', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HandwritingScreen(
          repository: MemoryHandwritingSampleStore(recognizedText: ''),
          imageExporter: () async => _tinyPng,
        ),
      ),
    );

    await _drawWriting(tester);
    await tester.tap(find.byKey(const ValueKey('submit_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save_sample_button')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No text was recognized in this image. You can still find the saved handwriting in My Writing.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('student can start a new sample after seeing the result', (
    tester,
  ) async {
    final repository = MemoryHandwritingSampleStore(
      recognizedText: 'Recognized',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HandwritingScreen(
          repository: repository,
          imageExporter: () async => _tinyPng,
        ),
      ),
    );

    await _drawWriting(tester);
    await tester.tap(find.byKey(const ValueKey('submit_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save_sample_button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('canvas_new_sample_button')),
    );
    await tester.tap(find.byKey(const ValueKey('canvas_new_sample_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('canvas_size')), findsOneWidget);
    expect(find.byKey(const ValueKey('canvas_ink_layer')), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const ValueKey('undo_button')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('upload failures appear in the save preview', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HandwritingScreen(
          repository: _FailingUploadStore(),
          imageExporter: () async => _tinyPng,
        ),
      ),
    );

    await _drawWriting(tester);
    await tester.tap(find.byKey(const ValueKey('submit_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save_sample_button')));
    await tester.pumpAndSettle();

    expect(find.text('The server rejected this sample.'), findsOneWidget);
    expect(find.text('Your handwriting is ready'), findsNothing);
  });

  testWidgets('My Writing displays saved samples and metadata', (tester) async {
    final repository = MemoryHandwritingSampleStore()
      ..addSample(
        id: 'visible',
        title: 'Practice sentence',
        imageBytes: _tinyPng,
      );

    await tester.pumpWidget(
      MaterialApp(home: MyWritingScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Practice sentence'), findsOneWidget);
    expect(find.text('1 saved sample'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('sample_thumbnail_visible')),
      findsOneWidget,
    );
  });

  testWidgets('a saved sample opens in its image detail screen', (
    tester,
  ) async {
    final repository = MemoryHandwritingSampleStore()
      ..addSample(
        id: 'open-me',
        title: 'Open this sample',
        imageBytes: _tinyPng,
        recognizedText: 'A real saved recognition result.',
      );

    await tester.pumpWidget(
      MaterialApp(home: MyWritingScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sample_card_open-me')));
    await tester.pumpAndSettle();

    expect(find.byType(SampleDetailScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('saved_sample_image')), findsOneWidget);
    expect(find.text('Open this sample'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('saved_sample_recognized_text')),
      findsOneWidget,
    );
    expect(find.text('A real saved recognition result.'), findsOneWidget);
  });

  testWidgets('My Writing adapts to phone, tablet, and laptop widths', (
    tester,
  ) async {
    const screenSizes = [Size(390, 844), Size(768, 1024), Size(1440, 900)];

    for (final size in screenSizes) {
      await tester.binding.setSurfaceSize(size);
      final repository = MemoryHandwritingSampleStore()
        ..addSample(
          id: 'responsive',
          title: 'Responsive sample',
          imageBytes: _tinyPng,
        );
      await tester.pumpWidget(
        MaterialApp(home: MyWritingScreen(repository: repository)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Responsive sample'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Layout at $size');
    }

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('deleting a sample removes it from the list and store', (
    tester,
  ) async {
    final repository = MemoryHandwritingSampleStore()
      ..addSample(
        id: 'delete-me',
        title: 'Remove this sample',
        imageBytes: _tinyPng,
      );

    await tester.pumpWidget(
      MaterialApp(home: MyWritingScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete_sample_delete-me')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(repository.deletedIds, ['delete-me']);
    expect(repository.samples, isEmpty);
    expect(repository.images, isEmpty);
    expect(
      find.text('Your saved handwriting samples will appear here.'),
      findsOneWidget,
    );
  });

  testWidgets('dashboard My writing entry opens the saved samples screen', (
    tester,
  ) async {
    final repository = MemoryHandwritingSampleStore();
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpWidget(LexGoApp(repository: repository));
    await tester.tap(find.text('My writing').first);
    await tester.pumpAndSettle();

    expect(find.byType(MyWritingScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.binding.setSurfaceSize(const Size(768, 1024));
    await tester.pumpWidget(LexGoApp(repository: repository));
    await tester.ensureVisible(find.widgetWithText(TextButton, 'My writing'));
    await tester.tap(find.widgetWithText(TextButton, 'My writing'));
    await tester.pumpAndSettle();

    expect(find.byType(MyWritingScreen), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
}

Future<void> _drawWriting(WidgetTester tester) async {
  final canvasRect = tester.getRect(find.byKey(const ValueKey('canvas_size')));
  final gesture = await tester.startGesture(
    Offset(canvasRect.left + 60, canvasRect.top + 80),
    kind: PointerDeviceKind.stylus,
  );
  await gesture.moveTo(Offset(canvasRect.left + 120, canvasRect.top + 100));
  await gesture.moveTo(Offset(canvasRect.left + 180, canvasRect.top + 90));
  await gesture.up();
  await tester.pump();
}

class _PendingUploadStore extends MemoryHandwritingSampleStore {
  final Completer<HandwritingSample> upload = Completer<HandwritingSample>();

  @override
  Future<HandwritingSample> saveSample({
    required String title,
    required Uint8List imageBytes,
  }) => upload.future;
}

class _FailingUploadStore extends MemoryHandwritingSampleStore {
  @override
  Future<HandwritingSample> saveSample({
    required String title,
    required Uint8List imageBytes,
  }) async {
    throw const HandwritingApiException('The server rejected this sample.');
  }
}
