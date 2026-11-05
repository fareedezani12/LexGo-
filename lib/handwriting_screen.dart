import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'lexgo_colors.dart';
import 'lexgo_ui.dart';
import 'models/handwriting_sample.dart';
import 'my_writing_screen.dart';
import 'recognition_result_widgets.dart';
import 'services/handwriting_api_service.dart';
import 'services/handwriting_sample_store.dart';

/// Handwriting canvas that uploads writing and displays the backend recognition result.
class HandwritingScreen extends StatefulWidget {
  final HandwritingSampleStore? repository;
  final Future<Uint8List> Function()? imageExporter;

  const HandwritingScreen({super.key, this.repository, this.imageExporter});

  @override
  State<HandwritingScreen> createState() => _HandwritingScreenState();
}

class _HandwritingScreenState extends State<HandwritingScreen> {
  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey _writingSurfaceKey = GlobalKey();
  late final HandwritingSampleStore _repository;
  List<InkStroke> _strokes = [];
  List<Offset>? _activePoints;
  int? _activePointer;
  _CanvasTool _tool = _CanvasTool.pen;
  PenThickness _penThickness = PenThickness.medium;
  bool _activeStrokeIsEraser = false;
  double _activeStrokeWidth = PenThickness.medium.width;
  HandwritingSample? _uploadedSample;
  Uint8List? _submittedImageBytes;

  bool get _hasWriting => _strokes.isNotEmpty || _activePoints != null;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? HandwritingApiService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: pageBackground,
        surfaceTintColor: pageBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: LexGoBackButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
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
            final canvasScale = constraints.maxWidth >= 1000 ? 0.7 : 0.54;
            final canvasHeight = (constraints.maxHeight * canvasScale)
                .clamp(400.0, 680.0)
                .toDouble();

            if (_uploadedSample != null) {
              return _recognitionResultView(constraints.maxWidth);
            }

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(sidePadding, 22, sidePadding, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CanvasPageHeader(isWide: isTablet),
                      const SizedBox(height: 22),
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
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.article_outlined,
                            size: 17,
                            color: indigo,
                          ),
                          const SizedBox(width: 7),
                          const Text(
                            'Lined practice page',
                            style: TextStyle(
                              color: ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          if (isTablet)
                            const Text(
                              'Use your finger or stylus',
                              style: TextStyle(color: muted, fontSize: 12),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Semantics(
                        label: 'Handwriting canvas. Draw using your finger or stylus.',
                        child: SizedBox(
                          key: const ValueKey('canvas_size'),
                          height: canvasHeight,
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: const Color(0xFFE1E7F0),
                                width: 1.2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x101E293B),
                                  blurRadius: 24,
                                  offset: Offset(0, 9),
                                ),
                                BoxShadow(
                                  color: Color(0x0A6366F1),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(21),
                              child: RepaintBoundary(
                                key: _writingSurfaceKey,
                                child: ColoredBox(
                                  color: Colors.white,
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
                              'Your writing is saved and recognized by LexGo after you submit it.',
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

  Future<void> _submit() async {
    if (!_hasWriting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something on the canvas first.')),
      );
      return;
    }

    _finishStroke();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => _SaveSampleDialog(
        strokes: _strokes,
        onSave: (title) async => _saveSample(title),
      ),
    );
  }

  Future<HandwritingSample> _saveSample(String title) async {
    final imageBytes = widget.imageExporter == null
        ? await _captureWritingPng()
        : await widget.imageExporter!();
    final sample = await _repository.saveSample(
      title: title.trim(),
      imageBytes: imageBytes,
    );
    if (mounted) {
      setState(() {
        _uploadedSample = sample;
        _submittedImageBytes = imageBytes;
      });
    }
    return sample;
  }

  Widget _recognitionResultView(double availableWidth) {
    final sample = _uploadedSample!;
    final imageBytes = _submittedImageBytes!;
    final recognizedText = sample.recognizedText?.trim() ?? '';
    final wideLayout = availableWidth >= 760;
    final sidePadding = availableWidth >= 680 ? 32.0 : 16.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(sidePadding, 22, sidePadding, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RecognitionResultHeader(),
              const SizedBox(height: 20),
              if (wideLayout)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: RecognitionImageCard(
                        imageBytes: imageBytes,
                        title: sample.title,
                        imageKey: const ValueKey('canvas_result_image'),
                        titleKey: const ValueKey('canvas_result_title'),
                        previewErrorMessage: 'The submitted image preview could not be displayed.',
                        height: 360,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: RecognitionTextCard(
                        recognizedText: recognizedText,
                        emptyMessage: 'No text was recognized in this image. You can still find the saved handwriting in My Writing.',
                        successMessage:
                            'Upload and recognition completed successfully.',
                        textKey: const ValueKey('canvas_recognized_text'),
                      ),
                    ),
                  ],
                )
              else ...[
                RecognitionImageCard(
                  imageBytes: imageBytes,
                  title: sample.title,
                  imageKey: const ValueKey('canvas_result_image'),
                  titleKey: const ValueKey('canvas_result_title'),
                  previewErrorMessage:
                      'The submitted image preview could not be displayed.',
                  height: 280,
                ),
                const SizedBox(height: 16),
                RecognitionTextCard(
                  recognizedText: recognizedText,
                  emptyMessage: 'No text was recognized in this image. You can still find the saved handwriting in My Writing.',
                  successMessage:
                      'Upload and recognition completed successfully.',
                  textKey: const ValueKey('canvas_recognized_text'),
                ),
              ],
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    key: const ValueKey('canvas_new_sample_button'),
                    onPressed: _startNewSample,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Start a new sample'),
                    style: FilledButton.styleFrom(backgroundColor: indigo),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey('canvas_my_writing_button'),
                    onPressed: () {
                      Navigator.of(context).pushReplacement<void, void>(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              MyWritingScreen(repository: _repository),
                        ),
                      );
                    },
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('Go to My Writing'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startNewSample() {
    setState(() {
      _uploadedSample = null;
      _submittedImageBytes = null;
      _strokes = [];
      _activePoints = null;
      _activePointer = null;
    });
  }

  Future<Uint8List> _captureWritingPng() async {
    final renderObject = _writingSurfaceKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw StateError('The handwriting canvas is not ready to save.');
    }

    final ui.Image image = await renderObject.toImage(pixelRatio: 2);
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError('The handwriting image could not be created.');
      }
      return byteData.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }
}

class _CanvasPageHeader extends StatelessWidget {
  final bool isWide;

  const _CanvasPageHeader({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final visualSize = isWide ? 88.0 : 66.0;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEEFC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 14, color: indigo),
                    SizedBox(width: 5),
                    Text(
                      'YOUR WRITING SPACE',
                      style: TextStyle(
                        color: indigo,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Write something',
                style: TextStyle(
                  color: ink,
                  fontSize: 27,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Take your time and write on the lines below.',
                style: TextStyle(color: muted, fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: visualSize,
          height: visualSize,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE9E9FF), Color(0xFFFFF1F8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                right: 10,
                top: 8,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: amber.withValues(alpha: 0.9),
                  size: isWide ? 20 : 16,
                ),
              ),
              Icon(
                Icons.edit_note_rounded,
                color: indigo,
                size: isWide ? 50 : 40,
              ),
              Positioned(
                left: 10,
                bottom: 9,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: pink,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 14 : 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE5E9F2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x081E293B),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.tune_rounded, color: indigo, size: 18),
                  const SizedBox(width: 7),
                  const Text(
                    'Drawing tools',
                    style: TextStyle(
                      color: ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    tool == _CanvasTool.pen
                        ? 'Pen selected'
                        : 'Eraser selected',
                    style: const TextStyle(color: muted, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 11),
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
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 5,
                        children: [
                          for (final thickness in PenThickness.values)
                            ChoiceChip(
                              key: ValueKey('${thickness.name}_thickness'),
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 17,
                                    height: 16,
                                    alignment: Alignment.center,
                                    child: Container(
                                      width: 15,
                                      height: thickness.width,
                                      decoration: BoxDecoration(
                                        color: thickness == penThickness
                                            ? indigo
                                            : muted,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(thickness.label),
                                ],
                              ),
                              selected: thickness == penThickness,
                              showCheckmark: false,
                              selectedColor: const Color(0xFFEDEEFC),
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                color: thickness == penThickness
                                    ? indigo.withValues(alpha: 0.55)
                                    : const Color(0xFFE2E8F0),
                              ),
                              labelStyle: TextStyle(
                                color: thickness == penThickness ? indigo : ink,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
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
                    style: ButtonStyle(
                      foregroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        return states.contains(WidgetState.selected)
                            ? indigo
                            : ink;
                      }),
                      backgroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        return states.contains(WidgetState.selected)
                            ? const Color(0xFFEDEEFC)
                            : Colors.white;
                      }),
                    ),
                    onSelectionChanged: (selection) =>
                        onToolChanged(selection.first),
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
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 9),
                child: Divider(height: 1, color: Color(0xFFEEF1F6)),
              ),
              if (compact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [_undoButton(), _clearButton()],
                    ),
                    const SizedBox(height: 10),
                    _submitButton(expand: true),
                  ],
                )
              else
                Row(
                  children: [
                    _undoButton(),
                    const SizedBox(width: 10),
                    _clearButton(),
                    const Spacer(),
                    _submitButton(),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _undoButton() => OutlinedButton.icon(
    key: const ValueKey('undo_button'),
    onPressed: canUndo ? onUndo : null,
    icon: const Icon(Icons.undo_rounded),
    label: const Text('Undo'),
    style: OutlinedButton.styleFrom(
      foregroundColor: ink,
      side: const BorderSide(color: Color(0xFFDCE2EC)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );

  Widget _clearButton() => OutlinedButton.icon(
    key: const ValueKey('clear_button'),
    onPressed: onClear,
    icon: const Icon(Icons.delete_outline_rounded),
    label: const Text('Clear'),
    style: OutlinedButton.styleFrom(
      foregroundColor: pink,
      backgroundColor: const Color(0xFFFFF7FB),
      side: const BorderSide(color: Color(0xFFF5D8E8)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );

  Widget _submitButton({bool expand = false}) => SizedBox(
    width: expand ? double.infinity : null,
    child: FilledButton.icon(
      key: const ValueKey('submit_button'),
      onPressed: onSubmit,
      style: FilledButton.styleFrom(
        backgroundColor: indigo,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: const Icon(Icons.auto_awesome_rounded),
      label: const Text('Submit'),
    ),
  );
}

/// Shows the lined-paper preview and asks the learner before saving it.
class _SaveSampleDialog extends StatefulWidget {
  final List<InkStroke> strokes;
  final Future<void> Function(String title) onSave;

  const _SaveSampleDialog({required this.strokes, required this.onSave});

  @override
  State<_SaveSampleDialog> createState() => _SaveSampleDialogState();
}

class _SaveSampleDialogState extends State<_SaveSampleDialog> {
  late final TextEditingController _titleController;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _titleController = TextEditingController(
      text:
          'Writing sample ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Enter a title to save this sample.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await widget.onSave(_titleController.text);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = error is HandwritingApiException
            ? error.message
            : 'The writing sample could not be uploaded. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Writing preview'),
      content: SizedBox(
        width: math.min(420.0, MediaQuery.sizeOf(context).width - 80),
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
                          painter: WritingPainter(strokes: widget.strokes),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('sample_title_field'),
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Sample title'),
              maxLength: 150,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 10),
            if (_isSaving)
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Uploading image and recognizing handwriting…',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ),
                ],
              )
            else
              const Text(
                'Submit this PNG to save it and recognize the handwriting.',
                style: TextStyle(color: muted, fontSize: 12, height: 1.4),
              ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          key: const ValueKey('save_sample_button'),
          onPressed: _isSaving ? null : _save,
          style: FilledButton.styleFrom(backgroundColor: indigo),
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_outlined),
          label: const Text('Save sample'),
        ),
      ],
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
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
      ..color = const Color(0xFFDDE5F0)
      ..strokeWidth = 1;
    for (var y = 42.0; y < size.height; y += 46) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guidePaint);
    }

    final marginPaint = Paint()
      ..color = const Color(0x44EC4899)
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(48, 0), Offset(48, size.height), marginPaint);
  }

  @override
  bool shouldRepaint(covariant _GuideLinesPainter oldDelegate) => false;
}
