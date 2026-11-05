import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';

import 'package:lexgo/handwriting_screen.dart';
import 'package:lexgo/main.dart';

import 'support/memory_handwriting_sample_store.dart';

const _canvasSizeKey = ValueKey('canvas_size');
const _undoButtonKey = ValueKey('undo_button');
const _clearButtonKey = ValueKey('clear_button');
const _submitButtonKey = ValueKey('submit_button');
const _thinThicknessKey = ValueKey('thin_thickness');
const _mediumThicknessKey = ValueKey('medium_thickness');
const _thickThicknessKey = ValueKey('thick_thickness');
const _canvasGuideLayerKey = ValueKey('canvas_guides_layer');
const _canvasInkLayerKey = ValueKey('canvas_ink_layer');
const _previewGuideLayerKey = ValueKey('preview_guides_layer');
const _previewInkLayerKey = ValueKey('preview_ink_layer');

void main() {
  testWidgets('Start writing opens the handwriting canvas', (tester) async {
    await tester.pumpWidget(
      LexGoApp(repository: MemoryHandwritingSampleStore()),
    );

    await tester.tap(find.text('Start writing'));
    await tester.pumpAndSettle();

    expect(find.byType(HandwritingScreen), findsOneWidget);
    expect(find.byKey(_canvasSizeKey), findsOneWidget);
    expect(find.text('Handwriting practice'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(find.text('Pen'), findsOneWidget);
    expect(find.text('Eraser'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
    expect(find.text('Submit'), findsOneWidget);
  });

  testWidgets('dashboard adapts to phone, tablet, and desktop widths', (
    tester,
  ) async {
    const sizes = [
      Size(390, 844),
      Size(768, 1024),
      Size(1440, 900),
    ];

    for (final size in sizes) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        LexGoApp(repository: MemoryHandwritingSampleStore()),
      );

      expect(find.text('Get started'), findsOneWidget);
      expect(find.text('Upload an image'), findsWidgets);
      expect(tester.takeException(), isNull, reason: 'Dashboard at $size');
    }

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('recent work shows an inviting empty state without sample data', (
    tester,
  ) async {
    await tester.pumpWidget(
      LexGoApp(repository: MemoryHandwritingSampleStore()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your first page starts here'), findsOneWidget);
    expect(find.text('Start writing'), findsWidgets);
    expect(find.textContaining('samples'), findsNothing);
  });

  testWidgets('recent work lists saved handwriting from the repository', (
    tester,
  ) async {
    final repository = MemoryHandwritingSampleStore()
      ..addSample(
        id: 'dashboard-recent',
        title: 'My latest practice',
        imageBytes: Uint8List.fromList([1, 2, 3]),
      );
    await tester.pumpWidget(LexGoApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('My latest practice'), findsOneWidget);
    expect(find.text('1 saved'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'My writing'), findsOneWidget);
  });

  testWidgets('Handwriting card opens the same screen', (tester) async {
    await tester.pumpWidget(
      LexGoApp(repository: MemoryHandwritingSampleStore()),
    );

    await tester.ensureVisible(find.text('Handwriting').first);
    await tester.tap(find.text('Handwriting').first);
    await tester.pumpAndSettle();

    expect(find.byType(HandwritingScreen), findsOneWidget);
  });

  testWidgets('canvas fits phone, tablet, and laptop screens', (tester) async {
    const screenSizes = [
      Size(390, 844), // Phone
      Size(768, 1024), // Tablet
      Size(1440, 900), // Laptop
    ];

    for (final size in screenSizes) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(const MaterialApp(home: HandwritingScreen()));

      expect(find.byKey(_canvasSizeKey), findsOneWidget);
      expect(
        tester.getSize(find.byKey(_canvasSizeKey)).height,
        greaterThanOrEqualTo(360),
      );
      expect(tester.takeException(), isNull, reason: 'Layout at $size');
    }

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('empty submit asks the learner to write first', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HandwritingScreen()));

    await tester.tap(find.byKey(_submitButtonKey));
    await tester.pump();

    expect(find.text('Write something on the canvas first.'), findsOneWidget);
  });

  testWidgets('stylus writing can be undone and submitted as a preview', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HandwritingScreen()));

    expect(
      tester.widget<OutlinedButton>(find.byKey(_undoButtonKey)).onPressed,
      isNull,
    );

    await _drawStroke(tester, PointerDeviceKind.stylus);
    expect(
      tester.widget<OutlinedButton>(find.byKey(_undoButtonKey)).onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(_undoButtonKey));
    await tester.pump();
    expect(
      tester.widget<OutlinedButton>(find.byKey(_undoButtonKey)).onPressed,
      isNull,
    );

    // Undo removed the only stroke, so Submit validates the now-empty canvas.
    await tester.tap(find.byKey(_submitButtonKey));
    await tester.pump();
    expect(find.text('Write something on the canvas first.'), findsOneWidget);

    await _drawStroke(tester, PointerDeviceKind.stylus);
    await tester.tap(find.byKey(_submitButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('Writing preview'), findsOneWidget);
    expect(
      find.text(
        'Submit this PNG to save it and recognize the handwriting.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('erase mode and clear control work', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HandwritingScreen()));

    expect(
      find.text('Pen selected. Choose a thickness, then draw.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Eraser'));
    await tester.pump();
    expect(
      find.text('Eraser selected. Draw over marks to remove them.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Pen'));
    await tester.pump();
    await _drawStroke(tester, PointerDeviceKind.stylus);
    expect(
      tester.widget<OutlinedButton>(find.byKey(_undoButtonKey)).onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(_clearButtonKey));
    await tester.pump();
    expect(
      tester.widget<OutlinedButton>(find.byKey(_undoButtonKey)).onPressed,
      isNull,
    );
  });

  testWidgets('Medium pen thickness is selected by default', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HandwritingScreen()));

    expect(
      tester.widget<ChoiceChip>(find.byKey(_thinThicknessKey)).selected,
      isFalse,
    );
    expect(
      tester.widget<ChoiceChip>(find.byKey(_mediumThicknessKey)).selected,
      isTrue,
    );
    expect(
      tester.widget<ChoiceChip>(find.byKey(_thickThicknessKey)).selected,
      isFalse,
    );
  });

  testWidgets('all pen thickness options can be selected', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HandwritingScreen()));

    await _selectThickness(tester, _thinThicknessKey);
    _expectSelectedThickness(tester, _thinThicknessKey);

    await _selectThickness(tester, _mediumThicknessKey);
    _expectSelectedThickness(tester, _mediumThicknessKey);

    await _selectThickness(tester, _thickThicknessKey);
    _expectSelectedThickness(tester, _thickThicknessKey);
  });

  testWidgets('new finger and stylus strokes use the selected thickness', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HandwritingScreen()));

    await _selectThickness(tester, _thinThicknessKey);
    await _drawStroke(tester, PointerDeviceKind.touch);
    expect(_strokeWidths(tester, _canvasInkLayerKey), [
      PenThickness.thin.width,
    ]);

    await tester.tap(find.byKey(_thickThicknessKey));
    await tester.pump();
    await _drawStroke(tester, PointerDeviceKind.stylus);
    expect(_strokeWidths(tester, _canvasInkLayerKey), [
      PenThickness.thin.width,
      PenThickness.thick.width,
    ]);
  });

  testWidgets('existing stroke widths stay the same in the preview', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HandwritingScreen()));

    await _drawStroke(tester, PointerDeviceKind.stylus);
    await _selectThickness(tester, _thickThicknessKey);
    await _drawStroke(tester, PointerDeviceKind.touch);
    await _selectThickness(tester, _thinThicknessKey);

    final originalWidths = [
      PenThickness.medium.width,
      PenThickness.thick.width,
    ];
    expect(_strokeWidths(tester, _canvasInkLayerKey), originalWidths);

    await tester.tap(find.byKey(_submitButtonKey));
    await tester.pumpAndSettle();

    expect(_strokeWidths(tester, _previewInkLayerKey), originalWidths);
  });

  testWidgets('canvas accepts finger touch input', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HandwritingScreen()));

    await _drawStroke(tester, PointerDeviceKind.touch);

    expect(
      tester.widget<OutlinedButton>(find.byKey(_undoButtonKey)).onPressed,
      isNotNull,
    );
  });

  testWidgets('eraser affects a separate ink layer above the paper', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HandwritingScreen()));

    _expectSeparateLayers(tester, _canvasGuideLayerKey, _canvasInkLayerKey);
    final guidePainter = tester
        .widget<CustomPaint>(find.byKey(_canvasGuideLayerKey))
        .painter;

    await _drawStrokeAcrossGuide(tester, guideY: 88);
    await tester.tap(find.text('Eraser'));
    await tester.pump();
    await _drawStrokeAcrossGuide(tester, guideY: 88);

    _expectSeparateLayers(tester, _canvasGuideLayerKey, _canvasInkLayerKey);
    expect(
      tester.widget<CustomPaint>(find.byKey(_canvasGuideLayerKey)).painter,
      same(guidePainter),
    );
  });

  testWidgets('Clear removes ink but keeps the paper guide layer', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HandwritingScreen()));

    _expectSeparateLayers(tester, _canvasGuideLayerKey, _canvasInkLayerKey);
    final guidePainter = tester
        .widget<CustomPaint>(find.byKey(_canvasGuideLayerKey))
        .painter;

    await _drawStrokeAcrossGuide(tester, guideY: 88);
    await tester.tap(find.byKey(_clearButtonKey));
    await tester.pump();

    _expectSeparateLayers(tester, _canvasGuideLayerKey, _canvasInkLayerKey);
    expect(
      tester.widget<CustomPaint>(find.byKey(_canvasGuideLayerKey)).painter,
      same(guidePainter),
    );
    expect(
      tester.widget<OutlinedButton>(find.byKey(_undoButtonKey)).onPressed,
      isNull,
    );
  });

  testWidgets('writing preview includes its guide lines', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HandwritingScreen()));

    await _drawStroke(tester, PointerDeviceKind.stylus);
    await tester.tap(find.byKey(_submitButtonKey));
    await tester.pumpAndSettle();

    _expectSeparateLayers(tester, _previewGuideLayerKey, _previewInkLayerKey);
  });
}

Future<void> _drawStroke(WidgetTester tester, PointerDeviceKind kind) async {
  final canvasRect = tester.getRect(find.byKey(_canvasSizeKey));
  final gesture = await tester.startGesture(
    Offset(canvasRect.left + 80, canvasRect.top + 100),
    kind: kind,
  );
  await gesture.moveTo(Offset(canvasRect.left + 150, canvasRect.top + 110));
  await gesture.moveTo(Offset(canvasRect.left + 220, canvasRect.top + 130));
  await gesture.up();
  await tester.pump();
}

Future<void> _drawStrokeAcrossGuide(
  WidgetTester tester, {
  required double guideY,
}) async {
  final canvasRect = tester.getRect(find.byKey(_canvasSizeKey));
  final gesture = await tester.startGesture(
    Offset(canvasRect.left + 80, canvasRect.top + guideY + 12),
    kind: PointerDeviceKind.stylus,
  );
  await gesture.moveTo(Offset(canvasRect.left + 120, canvasRect.top + guideY));
  await gesture.moveTo(
    Offset(canvasRect.left + 160, canvasRect.top + guideY - 20),
  );
  await gesture.up();
  await tester.pump();
}

void _expectSeparateLayers(WidgetTester tester, Key guideKey, Key inkKey) {
  final guideLayer = tester.widget<CustomPaint>(find.byKey(guideKey));
  final inkLayer = tester.widget<CustomPaint>(find.byKey(inkKey));

  expect(guideLayer.painter, isA<CustomPainter>());
  expect(inkLayer.painter, isA<CustomPainter>());
  expect(guideLayer.painter.runtimeType, isNot(inkLayer.painter.runtimeType));

  final stackFinder = find
      .ancestor(of: find.byKey(guideKey), matching: find.byType(Stack))
      .first;
  final stack = tester.widget<Stack>(stackFinder);
  final guideIndex = stack.children.indexWhere(
    (child) => child.key == guideKey,
  );
  final inkIndex = stack.children.indexWhere((child) => child.key == inkKey);
  expect(guideIndex, greaterThanOrEqualTo(0));
  expect(inkIndex, greaterThan(guideIndex));
}

Future<void> _selectThickness(WidgetTester tester, Key thicknessKey) async {
  await tester.tap(find.byKey(thicknessKey));
  await tester.pump();
}

void _expectSelectedThickness(WidgetTester tester, Key selectedKey) {
  for (final key in [
    _thinThicknessKey,
    _mediumThicknessKey,
    _thickThicknessKey,
  ]) {
    expect(
      tester.widget<ChoiceChip>(find.byKey(key)).selected,
      key == selectedKey,
    );
  }
}

List<double> _strokeWidths(WidgetTester tester, Key inkLayerKey) {
  final customPaint = tester.widget<CustomPaint>(find.byKey(inkLayerKey));
  final painter = customPaint.painter! as WritingPainter;
  return painter.strokes.map((stroke) => stroke.width).toList();
}
