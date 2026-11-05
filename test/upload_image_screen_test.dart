import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexgo/my_writing_screen.dart';
import 'package:lexgo/services/handwriting_api_service.dart';
import 'package:lexgo/upload_image_screen.dart';

import 'support/memory_handwriting_sample_store.dart';

final Uint8List _validPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/f0cAAAAASUVORK5CYII=',
);

void main() {
  testWidgets('Upload Image begins with a file selection action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UploadImageScreen(
          repository: MemoryHandwritingSampleStore(),
          imagePicker: () async => null,
        ),
      ),
    );

    expect(find.text('Add a handwriting image'), findsOneWidget);
    expect(find.byKey(const ValueKey('choose_image_button')), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('upload_image_button')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('rejects unsupported image formats and files over 10 MB', (
    tester,
  ) async {
    final selectedFiles = <UploadImageFile>[
      UploadImageFile(
        name: 'scan.gif',
        size: _validPng.length,
        bytes: _validPng,
      ),
      UploadImageFile(
        name: 'large.jpg',
        size: 10 * 1024 * 1024 + 1,
        bytes: _validPng,
      ),
    ];
    var nextFile = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: UploadImageScreen(
          repository: MemoryHandwritingSampleStore(),
          imagePicker: () async => selectedFiles[nextFile++],
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('choose_image_button')));
    await tester.pumpAndSettle();
    expect(find.text('Choose a PNG, JPG, or JPEG image.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('choose_image_button')));
    await tester.pumpAndSettle();
    expect(
      find.text('This image is larger than 10 MB. Choose a smaller image.'),
      findsOneWidget,
    );
  });

  testWidgets('selected image can be changed and removed', (tester) async {
    final files = <UploadImageFile>[
      UploadImageFile(
        name: 'first.png',
        size: _validPng.length,
        bytes: _validPng,
      ),
      UploadImageFile(
        name: 'second.jpeg',
        size: _validPng.length,
        bytes: _validPng,
      ),
    ];
    var nextFile = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: UploadImageScreen(
          repository: MemoryHandwritingSampleStore(),
          imagePicker: () async => files[nextFile++],
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('choose_image_button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('selected_image_preview')),
      findsOneWidget,
    );
    expect(find.text('first.png'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('change_image_button')));
    await tester.pumpAndSettle();
    expect(find.text('second.jpeg'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('remove_image_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('selected_image_preview')), findsNothing);
    expect(find.byKey(const ValueKey('choose_image_button')), findsOneWidget);
  });

  testWidgets('uploads titled image and then opens My Writing', (tester) async {
    final repository = MemoryHandwritingSampleStore(
      recognizedText: 'The quick brown fox',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: UploadImageScreen(
          repository: repository,
          imageEncoder: (_) async => _validPng,
          imagePicker: () async => UploadImageFile(
            name: 'practice.jpg',
            size: _validPng.length,
            bytes: _validPng,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('choose_image_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('upload_title_field')),
      'Imported practice',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('upload_image_button')),
    );
    await tester.tap(find.byKey(const ValueKey('upload_image_button')));
    await tester.pumpAndSettle();

    expect(repository.samples, hasLength(1));
    expect(repository.samples.single.title, 'Imported practice');
    expect(repository.images[repository.samples.single.id], isNotEmpty);
    expect(find.text('Image uploaded successfully.'), findsOneWidget);
    expect(find.byKey(const ValueKey('recognition_result_image')), findsOneWidget);
    expect(find.text('Imported practice'), findsOneWidget);
    expect(find.text('The quick brown fox'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('open_my_writing_button')));
    await tester.pumpAndSettle();
    expect(find.byType(MyWritingScreen), findsOneWidget);
  });

  testWidgets('shows a helpful message when no text is recognized', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UploadImageScreen(
          repository: MemoryHandwritingSampleStore(recognizedText: ''),
          imageEncoder: (_) async => _validPng,
          imagePicker: () async => UploadImageFile(
            name: 'blank.png',
            size: _validPng.length,
            bytes: _validPng,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('choose_image_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('upload_title_field')),
      'Blank page',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('upload_image_button')));
    await tester.tap(find.byKey(const ValueKey('upload_image_button')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No text was recognized in this image. You can still view the saved image in My Writing.',
      ),
      findsOneWidget,
    );
    expect(find.text('Image uploaded successfully.'), findsOneWidget);
  });

  testWidgets('shows API errors and stays on the upload screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UploadImageScreen(
          repository: MemoryHandwritingSampleStore(
            saveError: const HandwritingApiException(
              'Handwriting recognition service is unavailable. Please try again.',
            ),
          ),
          imageEncoder: (_) async => _validPng,
          imagePicker: () async => UploadImageFile(
            name: 'practice.png',
            size: _validPng.length,
            bytes: _validPng,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('choose_image_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('upload_title_field')),
      'Practice',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('upload_image_button')));
    await tester.tap(find.byKey(const ValueKey('upload_image_button')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Handwriting recognition service is unavailable. Please try again.',
      ),
      findsOneWidget,
    );
    expect(find.byType(MyWritingScreen), findsNothing);
  });

  testWidgets('requires a sample title before upload', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UploadImageScreen(
          repository: MemoryHandwritingSampleStore(),
          imagePicker: () async => UploadImageFile(
            name: 'practice.png',
            size: _validPng.length,
            bytes: _validPng,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('choose_image_button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('upload_image_button')),
    );
    await tester.tap(find.byKey(const ValueKey('upload_image_button')));
    await tester.pump();

    expect(find.text('Add a title before saving this image.'), findsOneWidget);
  });
}
