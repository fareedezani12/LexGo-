import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'lexgo_colors.dart';

/// A local handwriting canvas. It does not recognise or save the writing.
class HandwritingScreen extends StatefulWidget {
  const HandwritingScreen({super.key});

  @override
  State<HandwritingScreen> createState() => _HandwritingScreenState();
}

class _HandwritingScreenState extends State<HandwritingScreen> {
  final GlobalKey _canvasKey = GlobalKey();
  List<InkStroke> _strokes = [];
  List<Offset>? _activePoints;
  int? _activePointer;
  _CanvasTool _tool = _CanvasTool.pen;
  PenThickness _penThickness = PenThickness.medium;
  bool _activeStrokeIsEraser = false;
  double _activeStrokeWidth = PenThickness.medium.width;

  bool get _hasWriting => _strokes.isNotEmpty || _activePoints != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          tooltip: 'Back to dashboard',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Handwriting practice',
          style: TextStyle(color: ink, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 680;
            final sidePadding = isTablet ? 32.0 : 16.0;
            final canvasHeight = math.max(
              360.0,
              math.min(680.0, constraints.maxHeight - 230),
            );

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(sidePadding, 22, sidePadding, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Write something',
                        style: TextStyle(
                          color: ink,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Use your finger or stylus on the lined page.',
                        style: TextStyle(color: muted, fontSize: 14),
                      ),
                      const SizedBox(height: 18),
                      _CanvasToolbar(
                        canUndo: _strokes.isNotEmpty,
                        tool: _tool,
                        penThickness: _penThickness,
                        onUndo: _undo,
                        onToolChanged: (tool) => setState(() => _tool = tool),
                        onThicknessChanged: (thickness) =>
                            setState(() => _penThickness = thickness),
                        onClear: _clear,
                        onSubmit: _submit,
                      ),
                      const SizedBox(height: 14),
                      Semantics(
                        label: 'Handwriting canvas. Draw using your finger or stylus.',
                        child: SizedBox(
                          key: const ValueKey('canvas_size'),
                          height: canvasHeight,
                          width: double.infinity,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: RepaintBoundary(
                              key: const ValueKey('writing_surface_boundary'),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x0A1E293B),
                                      blurRadius: 18,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    const CustomPaint(
                                      key: ValueKey('canvas_guides_layer'),
                                      painter: _GuideLinesPainter(),
                                    ),
                                    CustomPaint(
                                      key: const ValueKey('canvas_ink_layer'),
                                      painter: WritingPainter(
                                        strokes: _strokes,
                                        activePoints: _activePoints,
                                        activeIsEraser: _activeStrokeIsEraser,
                                        activeWidth: _activeStrokeWidth,
                                      ),
                                    ),
                                    Listener(
                                      key: _canvasKey,
                                      behavior: HitTestBehavior.opaque,
                                      onPointerDown: _onPointerDown,
                                      onPointerMove: _onPointerMove,
                                      onPointerUp: _onPointerUp,
                                      onPointerCancel: _onPointerCancel,
                                      child: const SizedBox.expand(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: muted,
                          ),
                          SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              'Your writing stays on this screen for now. Recognition is not connected.',
                              style: TextStyle(
                                color: muted,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      backgroundColor: pageBackground,
    );
  }

  Offset _normalise(Offset localPosition, Size size) {
    return Offset(
      (localPosition.dx / size.width).clamp(0.0, 1.0).toDouble(),
      (localPosition.dy / size.height).clamp(0.0, 1.0).toDouble(),
    );
  }

  Offset? _localPosition(PointerEvent event) {
    final renderObject = _canvasKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    final localPosition = renderObject.globalToLocal(event.position);
    return _normalise(localPosition, renderObject.size);
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_activePointer != null) return;
    final point = _localPosition(event);
    if (point == null) return;

    setState(() {
      _activePointer = event.pointer;
      _activePoints = [point];
      _activeStrokeIsEraser = _tool == _CanvasTool.eraser;
      _activeStrokeWidth = _tool == _CanvasTool.eraser
          ? 22
          : _penThickness.width;
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer) return;
    final point = _localPosition(event);
    if (point == null) return;

    setState(() => _activePoints = [...?_activePoints, point]);
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer == _activePointer) _finishStroke();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer == _activePointer) _finishStroke();
  }

  void _finishStroke() {
    final points = _activePoints;
    if (points == null || points.isEmpty) return;

    setState(() {
      _strokes = [
        ..._strokes,
        InkStroke(
          points: List<Offset>.unmodifiable(points),
          isEraser: _activeStrokeIsEraser,
          width: _activeStrokeWidth,
        ),
      ];
      _activePoints = null;
      _activePointer = null;
    });
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() => _strokes = [..._strokes]..removeLast());
  }

  void _clear() {
    setState(() {
      _strokes = [];
      _activePoints = null;
      _activePointer = null;
    });
  }

  void _submit() {
    if (!_hasWriting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something on the canvas first.')),
      );
      return;
    }

    _finishStroke();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Writing preview'),
        content: SizedBox(
          width: math.min(360.0, MediaQuery.sizeOf(context).width - 80),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ColoredBox(
                    color: Colors.white,
                    child: RepaintBoundary(
                      key: const ValueKey('preview_surface_boundary'),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const CustomPaint(
                            key: ValueKey('preview_guides_layer'),
                            painter: _GuideLinesPainter(),
                          ),
                          CustomPaint(
                            key: const ValueKey('preview_ink_layer'),
                            painter: WritingPainter(strokes: _strokes),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This is a visual preview. Handwriting recognition is not connected.',
                style: TextStyle(color: muted, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      ),
    );
  }
}

class _CanvasToolbar extends StatelessWidget {
  final bool canUndo;
  final _CanvasTool tool;
  final PenThickness penThickness;
  final VoidCallback onUndo;
  final ValueChanged<_CanvasTool> onToolChanged;
  final ValueChanged<PenThickness> onThicknessChanged;
  final VoidCallback onClear;
  final VoidCallback onSubmit;

  const _CanvasToolbar({
    required this.canUndo,
    required this.tool,
    required this.penThickness,
    required this.onUndo,
    required this.onToolChanged,
    required this.onThicknessChanged,
    required this.onClear,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pen thickness',
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 4,
                  children: [
                    for (final thickness in PenThickness.values)
                      ChoiceChip(
                        key: ValueKey('${thickness.name}_thickness'),
                        label: Text(thickness.label),
                        selected: thickness == penThickness,
                        showCheckmark: true,
                        selectedColor: indigo,
                        labelStyle: TextStyle(
                          color: thickness == penThickness ? Colors.white : ink,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) => onThicknessChanged(thickness),
                      ),
                  ],
                ),
              ],
            ),
            SegmentedButton<_CanvasTool>(
              key: const ValueKey('tool_selector'),
              segments: const [
                ButtonSegment(
                  value: _CanvasTool.pen,
                  icon: Icon(Icons.edit_rounded),
                  label: Text('Pen'),
                ),
                ButtonSegment(
                  value: _CanvasTool.eraser,
                  icon: Icon(Icons.backspace_outlined),
                  label: Text('Eraser'),
                ),
              ],
              selected: {tool},
              showSelectedIcon: true,
              onSelectionChanged: (selection) => onToolChanged(selection.first),
            ),
            OutlinedButton.icon(
              key: const ValueKey('undo_button'),
              onPressed: canUndo ? onUndo : null,
              icon: const Icon(Icons.undo_rounded),
              label: const Text('Undo'),
            ),
            OutlinedButton.icon(
              key: const ValueKey('clear_button'),
              onPressed: onClear,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Clear'),
            ),
            FilledButton.icon(
              key: const ValueKey('submit_button'),
              onPressed: onSubmit,
              style: FilledButton.styleFrom(backgroundColor: indigo),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Submit'),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          tool == _CanvasTool.eraser
              ? 'Eraser selected. Draw over marks to remove them.'
              : 'Pen selected. Choose a thickness, then draw.',
          key: const ValueKey('tool_help_text'),
          style: const TextStyle(color: muted, fontSize: 12),
        ),
      ],
    );
  }
}

enum _CanvasTool { pen, eraser }

enum PenThickness {
  thin('Thin', 2.0),
  medium('Medium', 3.4),
  thick('Thick', 5.6);

  final String label;
  final double width;

  const PenThickness(this.label, this.width);
}

/// One completed pen or eraser gesture, with its original stroke width.
class InkStroke {
  final List<Offset> points;
  final bool isEraser;
  final double width;

  const InkStroke({
    required this.points,
    required this.isEraser,
    required this.width,
  });
}

/// Paints user marks on a transparent layer above the lined paper.
/// Paints saved strokes onto a transparent layer above the paper guides.
class WritingPainter extends CustomPainter {
  final List<InkStroke> strokes;
  final List<Offset>? activePoints;
  final bool activeIsEraser;
  final double activeWidth;

  const WritingPainter({
    required this.strokes,
    this.activePoints,
    this.activeIsEraser = false,
    this.activeWidth = 3.4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Clear operations are limited to marks painted inside this layer.
    canvas.saveLayer(Offset.zero & size, Paint());
    for (final stroke in strokes) {
      _paintStroke(
        canvas,
        size,
        stroke.points,
        stroke.width,
        isEraser: stroke.isEraser,
      );
    }
    if (activePoints != null) {
      _paintStroke(
        canvas,
        size,
        activePoints!,
        activeWidth,
        isEraser: activeIsEraser,
      );
    }
    canvas.restore();
  }

  void _paintStroke(
    Canvas canvas,
    Size size,
    List<Offset> points,
    double width, {
    required bool isEraser,
  }) {
    if (points.isEmpty) return;

    final strokePaint = Paint()
      ..color = ink
      ..blendMode = isEraser ? BlendMode.clear : BlendMode.srcOver
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final first = Offset(
      points.first.dx * size.width,
      points.first.dy * size.height,
    );

    if (points.length == 1) {
      canvas.drawCircle(
        first,
        width / 2,
        strokePaint..style = PaintingStyle.fill,
      );
      return;
    }

    final path = Path()..moveTo(first.dx, first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx * size.width, point.dy * size.height);
    }
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant WritingPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.activePoints != activePoints ||
        oldDelegate.activeIsEraser != activeIsEraser ||
        oldDelegate.activeWidth != activeWidth;
  }
}

/// Draws the lined paper independently beneath the transparent ink layer.
class _GuideLinesPainter extends CustomPainter {
  const _GuideLinesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = const Color(0xFFE7EDF5)
      ..strokeWidth = 1;
    for (var y = 42.0; y < size.height; y += 46) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guidePaint);
    }

    final marginPaint = Paint()
      ..color = const Color(0x33EC4899)
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(48, 0), Offset(48, size.height), marginPaint);
  }

  @override
  bool shouldRepaint(covariant _GuideLinesPainter oldDelegate) => false;
}
