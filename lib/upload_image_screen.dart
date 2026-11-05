import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'models/handwriting_sample.dart';
import 'lexgo_colors.dart';
import 'lexgo_ui.dart';
import 'my_writing_screen.dart';
import 'recognition_result_widgets.dart';
import 'services/handwriting_api_service.dart';
import 'services/handwriting_sample_store.dart';

const int _maximumImageBytes = 10 * 1024 * 1024;

/// An image file picked by the learner, with its bytes ready for preview.
class UploadImageFile {
  final String name;
  final int size;
  final Uint8List bytes;

  const UploadImageFile({
    required this.name,
    required this.size,
    required this.bytes,
  });
}

class UploadImageScreen extends StatefulWidget {
  final HandwritingSampleStore repository;
  final Future<UploadImageFile?> Function()? imagePicker;
  final Future<Uint8List> Function(Uint8List imageBytes)? imageEncoder;

  const UploadImageScreen({
    super.key,
    required this.repository,
    this.imagePicker,
    this.imageEncoder,
  });

  @override
  State<UploadImageScreen> createState() => _UploadImageScreenState();
}

class _UploadImageScreenState extends State<UploadImageScreen> {
  final TextEditingController _titleController = TextEditingController();
  UploadImageFile? _selectedImage;
  bool _isUploading = false;
  String? _errorMessage;
  HandwritingSample? _uploadedSample;
  Uint8List? _uploadedImageBytes;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
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
          onPressed: _isUploading ? null : () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          _uploadedSample == null ? 'Upload an image' : 'Handwriting Result',
          style: TextStyle(color: ink, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding = constraints.maxWidth >= 680 ? 32.0 : 16.0;
            final isWide = constraints.maxWidth >= 720;
            if (_uploadedSample != null) {
              return _resultView(constraints.maxWidth);
            }
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(padding, 24, padding, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _UploadPageHeader(isWide: isWide),
                      const SizedBox(height: 24),
                      _imagePanel(),
                      const SizedBox(height: 22),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isWide ? 20 : 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE5E9F2)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x071E293B),
                              blurRadius: 16,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.label_outline_rounded,
                                  color: indigo,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Give your page a name',
                                  style: TextStyle(
                                    color: ink,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              key: const ValueKey('upload_title_field'),
                              controller: _titleController,
                              enabled: !_isUploading,
                              maxLength: 150,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                labelText: 'Sample title',
                                hintText: 'For example, My practice page',
                                prefixIcon: const Icon(
                                  Icons.edit_note_rounded,
                                  color: muted,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFFAFBFF),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 15,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: indigo,
                                    width: 1.7,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 14),
                        _StatusMessage(message: _errorMessage!, isError: true),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          key: const ValueKey('upload_image_button'),
                          onPressed: _selectedImage == null || _isUploading
                              ? null
                              : _uploadImage,
                          style: FilledButton.styleFrom(
                            backgroundColor: indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: _isUploading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.cloud_upload_outlined),
                          label: Text(
                            _isUploading
                                ? 'Uploading and recognizing…'
                                : 'Upload and recognize',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      if (_isUploading) ...[
                        const SizedBox(height: 14),
                        const _UploadProgressMessage(),
                      ],
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

  Widget _imagePanel() {
    final image = _selectedImage;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(image == null ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E9F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x081E293B),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: image == null
          ? Column(
              children: [
                CustomPaint(
                  foregroundPainter: _DashedRoundedBorderPainter(
                    color: indigo.withValues(alpha: 0.48),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE9E9FF), Color(0xFFFFEFF7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.cloud_upload_rounded,
                            color: indigo,
                            size: 38,
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'Choose a handwriting page',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Select a clear photo or scan from your device.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: muted, fontSize: 13),
                        ),
                        const SizedBox(height: 14),
                        const Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _UploadInfoPill(
                              icon: Icons.image_outlined,
                              label: 'JPG · JPEG · PNG',
                            ),
                            _UploadInfoPill(
                              icon: Icons.data_usage_rounded,
                              label: 'Up to 10 MB',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'JPG and JPEG images are prepared as PNG for upload.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: muted, fontSize: 11),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          key: const ValueKey('choose_image_button'),
                          onPressed: _isUploading ? null : _chooseImage,
                          icon: const Icon(Icons.folder_open_rounded),
                          label: const Text('Choose an image'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: indigo,
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFDCDDFA)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 260,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFAFBFF), Color(0xFFF5F7FC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE8ECF3)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.memory(
                          image.bytes,
                          key: const ValueKey('selected_image_preview'),
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Center(
                            child: Text(
                              'This image preview could not be displayed.',
                              style: TextStyle(color: muted),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE5E9F2)),
                          ),
                          child: const Text(
                            'IMAGE PREVIEW',
                            style: TextStyle(
                              color: muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.image_outlined, size: 18, color: indigo),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            image.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ink,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            _formatBytes(image.size),
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      key: const ValueKey('change_image_button'),
                      onPressed: _isUploading ? null : _chooseImage,
                      style: TextButton.styleFrom(foregroundColor: indigo),
                      child: const Text('Change'),
                    ),
                    IconButton(
                      key: const ValueKey('remove_image_button'),
                      tooltip: 'Remove selected image',
                      onPressed: _isUploading ? null : _removeImage,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFFFF1F7),
                        foregroundColor: pink,
                      ),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Future<void> _chooseImage() async {
    setState(() => _errorMessage = null);
    try {
      final file = widget.imagePicker == null
          ? await _pickImageFromDevice()
          : await widget.imagePicker!();
      if (file == null || !mounted) return;

      final validationMessage = _validateImage(file);
      if (validationMessage != null) {
        setState(() => _errorMessage = validationMessage);
        return;
      }

      try {
        final codec = await ui.instantiateImageCodec(file.bytes);
        codec.dispose();
      } catch (_) {
        setState(() {
          _errorMessage = 'This file could not be opened as an image.';
        });
        return;
      }

      setState(() {
        _selectedImage = file;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'The image could not be selected. Please try again.';
      });
    }
  }

  Future<UploadImageFile?> _pickImageFromDevice() async {
    final files = await FilePicker.pickFiles(
      dialogTitle: 'Choose a handwriting image',
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg'],
    );
    if (files.isEmpty) return null;

    final file = files.single;
    final size = file.lengthSync() ?? await file.length();
    if (size == null) {
      throw StateError('The selected file size could not be read.');
    }
    if (size > _maximumImageBytes) {
      return UploadImageFile(name: file.name, size: size, bytes: Uint8List(0));
    }
    final bytes = await file.readAsBytes();
    return UploadImageFile(name: file.name, size: size, bytes: bytes);
  }

  String? _validateImage(UploadImageFile file) {
    final extension = file.name.split('.').last.toLowerCase();
    if (!const {'png', 'jpg', 'jpeg'}.contains(extension)) {
      return 'Choose a PNG, JPG, or JPEG image.';
    }
    if (file.size > _maximumImageBytes) {
      return 'This image is larger than 10 MB. Choose a smaller image.';
    }
    if (file.bytes.isEmpty) return 'This image file is empty.';
    return null;
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _errorMessage = null;
    });
  }

  Future<void> _uploadImage() async {
    final selectedImage = _selectedImage;
    if (selectedImage == null) return;
    if (_titleController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Add a title before saving this image.');
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final pngBytes = widget.imageEncoder == null
          ? await _convertToPng(selectedImage.bytes)
          : await widget.imageEncoder!(selectedImage.bytes);
      if (pngBytes.lengthInBytes > _maximumImageBytes) {
        throw const _UploadValidationException(
          'The converted PNG is larger than 10 MB. Choose a smaller image.',
        );
      }

      final sample = await widget.repository.saveSample(
        title: _titleController.text.trim(),
        imageBytes: pngBytes,
      );
      if (!mounted) return;
      setState(() {
        _uploadedSample = sample;
        _uploadedImageBytes = pngBytes;
      });
    } on _UploadValidationException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error is HandwritingApiException ? error.message : 'The image could not be uploaded. Check your connection and try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _resultView(double availableWidth) {
    final sample = _uploadedSample!;
    final imageBytes = _uploadedImageBytes!;
    final recognizedText = sample.recognizedText?.trim() ?? '';
    final wideLayout = availableWidth >= 720;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        availableWidth >= 680 ? 32 : 16,
        24,
        availableWidth >= 680 ? 32 : 16,
        32,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
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
                        imageKey: const ValueKey('recognition_result_image'),
                        titleKey: const ValueKey('recognition_result_title'),
                        previewErrorMessage:
                            'This image preview could not be displayed.',
                        height: 350,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: RecognitionTextCard(
                        recognizedText: recognizedText,
                        emptyMessage: 'No text was recognized in this image. You can still view the saved image in My Writing.',
                        successMessage: 'Image uploaded successfully.',
                        textKey: const ValueKey('recognition_result_text'),
                      ),
                    ),
                  ],
                )
              else ...[
                RecognitionImageCard(
                  imageBytes: imageBytes,
                  title: sample.title,
                  imageKey: const ValueKey('recognition_result_image'),
                  titleKey: const ValueKey('recognition_result_title'),
                  previewErrorMessage:
                      'This image preview could not be displayed.',
                  height: 260,
                ),
                const SizedBox(height: 16),
                RecognitionTextCard(
                  recognizedText: recognizedText,
                  emptyMessage: 'No text was recognized in this image. You can still view the saved image in My Writing.',
                  successMessage: 'Image uploaded successfully.',
                  textKey: const ValueKey('recognition_result_text'),
                ),
              ],
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    key: const ValueKey('open_my_writing_button'),
                    onPressed: _openMyWriting,
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('Go to My Writing'),
                    style: FilledButton.styleFrom(backgroundColor: indigo),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey('upload_another_button'),
                    onPressed: () {
                      setState(() {
                        _uploadedSample = null;
                        _uploadedImageBytes = null;
                        _selectedImage = null;
                        _titleController.clear();
                      });
                    },
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Upload another image'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openMyWriting() {
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(
        builder: (_) => MyWritingScreen(repository: widget.repository),
      ),
    );
  }

  Future<Uint8List> _convertToPng(Uint8List imageBytes) async {
    final codec = await ui.instantiateImageCodec(imageBytes);
    try {
      final frame = await codec.getNextFrame();
      try {
        final data = await frame.image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (data == null) {
          throw const _UploadValidationException(
            'This image could not be prepared for upload.',
          );
        }
        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }
}

class _StatusMessage extends StatelessWidget {
  final String message;
  final bool isError;

  const _StatusMessage({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFFF1F2) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? const Color(0xFFFBCFE8) : const Color(0xFFBBF7D0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
            color: isError ? pink : const Color(0xFF059669),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError
                    ? const Color(0xFFBE123C)
                    : const Color(0xFF047857),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadPageHeader extends StatelessWidget {
  final bool isWide;

  const _UploadPageHeader({required this.isWide});

  @override
  Widget build(BuildContext context) {
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
                  color: const Color(0xFFFCE7F3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 14, color: pink),
                    SizedBox(width: 5),
                    Text(
                      'LET’S GET IT READY',
                      style: TextStyle(
                        color: pink,
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
                'Add a handwriting image',
                style: TextStyle(
                  color: ink,
                  fontSize: 25,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Choose a clear page and LexGo will read the handwriting for you.',
                style: TextStyle(color: muted, fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: isWide ? 82 : 64,
          height: isWide ? 82 : 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFEAF4), Color(0xFFFFF7E7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(23),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.document_scanner_outlined,
                color: pink,
                size: isWide ? 42 : 34,
              ),
              Positioned(
                right: 7,
                top: 7,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: amber.withValues(alpha: 0.9),
                  size: isWide ? 17 : 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UploadInfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _UploadInfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E7F5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: indigo, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: ink,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadProgressMessage extends StatelessWidget {
  const _UploadProgressMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E4FF)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: indigo,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'LexGo is reading your handwriting…',
                  style: TextStyle(
                    color: ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(5)),
            child: LinearProgressIndicator(
              minHeight: 5,
              color: indigo,
              backgroundColor: Color(0xFFDADCFB),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedRoundedBorderPainter extends CustomPainter {
  final Color color;

  const _DashedRoundedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final borderPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (final metric in borderPath.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final dashEnd = math.min(distance + 8, metric.length);
        canvas.drawPath(metric.extractPath(distance, dashEnd), paint);
        distance += 14;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _UploadValidationException implements Exception {
  final String message;

  const _UploadValidationException(this.message);
}

String _formatBytes(int bytes) {
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
