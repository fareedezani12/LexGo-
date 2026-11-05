import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'handwriting_screen.dart';
import 'lexgo_colors.dart';
import 'lexgo_ui.dart';
import 'models/handwriting_sample.dart';
import 'services/handwriting_api_service.dart';
import 'services/handwriting_sample_store.dart';

class MyWritingScreen extends StatefulWidget {
  final HandwritingSampleStore repository;

  const MyWritingScreen({super.key, required this.repository});

  @override
  State<MyWritingScreen> createState() => _MyWritingScreenState();
}

class _MyWritingScreenState extends State<MyWritingScreen> {
  List<HandwritingSample> _samples = [];
  final Map<String, Uint8List> _images = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSamples();
  }

  Future<void> _loadSamples() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final samples = await widget.repository.loadSamples();
      final images = <String, Uint8List>{};
      for (final sample in samples) {
        try {
          images[sample.id] = await widget.repository.loadImage(sample);
        } catch (_) {
          // Keep the record visible so it can still be removed if its file is gone.
        }
      }
      if (!mounted) return;
      setState(() {
        _samples = samples;
        _images
          ..clear()
          ..addAll(images);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error is HandwritingApiException
            ? error.message
            : 'Your saved writing could not be loaded. Please try again.';
      });
    }
  }

  Future<void> _openSample(HandwritingSample sample) async {
    final image = _images[sample.id];
    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The saved image could not be opened.')),
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SampleDetailScreen(sample: sample, imageBytes: image),
      ),
    );
  }

  Future<void> _confirmDelete(HandwritingSample sample) async {
    if (widget.repository is HandwritingApiService) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Deleting saved samples is not available in the backend yet.',
          ),
        ),
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this sample?'),
        content: Text(
          '“${sample.title}” will be removed from your saved writing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: indigo),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await widget.repository.deleteSample(sample);
      if (!mounted) return;
      setState(() {
        _samples = _samples.where((item) => item.id != sample.id).toList();
        _images.remove(sample.id);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Writing sample deleted.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is HandwritingApiException
                ? error.message
                : 'The writing sample could not be deleted.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: LexGoBackButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'My Writing',
          style: TextStyle(color: ink, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding = constraints.maxWidth >= 680 ? 32.0 : 16.0;
            final columns = constraints.maxWidth >= 980
                ? 3
                : (constraints.maxWidth >= 560 ? 2 : 1);
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(padding, 22, padding, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LibraryHeader(
                        sampleCount: _samples.length,
                        onStartWriting: _startWriting,
                      ),
                      const SizedBox(height: 22),
                      if (_isLoading)
                        const _LoadingPanel()
                      else if (_errorMessage != null)
                        _MessagePanel(
                          icon: Icons.cloud_off_rounded,
                          message: _errorMessage!,
                          buttonLabel: 'Try again',
                          onPressed: _loadSamples,
                          isError: true,
                        )
                      else if (_samples.isEmpty)
                        _MessagePanel(
                          icon: Icons.edit_note_rounded,
                          message: 'Your saved handwriting samples will appear here.',
                          buttonLabel: 'Start writing',
                          onPressed: _startWriting,
                        )
                      else
                        GridView.builder(
                          itemCount: _samples.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                mainAxisExtent: columns == 1 ? 184 : 326,
                              ),
                          itemBuilder: (context, index) {
                            final sample = _samples[index];
                            return _SampleCard(
                              sample: sample,
                              imageBytes: _images[sample.id],
                              compact: columns == 1,
                              onOpen: () => _openSample(sample),
                              onDelete: () => _confirmDelete(sample),
                            );
                          },
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

  Future<void> _startWriting() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HandwritingScreen(repository: widget.repository),
      ),
    );
    if (mounted) await _loadSamples();
  }
}

class SampleDetailScreen extends StatelessWidget {
  final HandwritingSample sample;
  final Uint8List imageBytes;

  const SampleDetailScreen({
    super.key,
    required this.sample,
    required this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    final recognizedText = sample.recognizedText?.trim() ?? '';
    return Scaffold(
      appBar: AppBar(
        leading: LexGoBackButton(
          tooltip: 'Back to My Writing',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          sample.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: ink, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final preview = _SampleImagePanel(imageBytes: imageBytes);
            final textPanel = _RecognitionPanel(recognizedText: recognizedText);
            return SingleChildScrollView(
              padding: EdgeInsets.all(constraints.maxWidth >= 680 ? 28 : 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF0F0FF), Color(0xFFFFF3F9)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE6E7FA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.menu_book_rounded,
                              color: indigo,
                              size: 26,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Saved handwriting',
                                    style: TextStyle(
                                      color: ink,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatSampleDate(sample.createdAt),
                                    style: const TextStyle(
                                      color: muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: preview),
                            const SizedBox(width: 18),
                            Expanded(child: textPanel),
                          ],
                        )
                      else ...[
                        preview,
                        const SizedBox(height: 16),
                        textPanel,
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
}

class _LibraryHeader extends StatelessWidget {
  final int sampleCount;
  final VoidCallback onStartWriting;

  const _LibraryHeader({
    required this.sampleCount,
    required this.onStartWriting,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0F0FF), Color(0xFFFFF3F9), Color(0xFFFFFAEC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6E7FA)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          final intro = Expanded(
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: indigo,
                    size: 29,
                  ),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Writing',
                        style: TextStyle(
                          color: ink,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Your saved handwriting pages, all in one place.',
                        style: TextStyle(
                          color: muted,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
          final action = FilledButton.icon(
            onPressed: onStartWriting,
            style: FilledButton.styleFrom(
              backgroundColor: indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Start writing'),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isWide)
                Row(children: [intro, const SizedBox(width: 16), action])
              else ...[
                Row(children: [intro]),
                const SizedBox(height: 14),
                SizedBox(width: double.infinity, child: action),
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$sampleCount saved ${sampleCount == 1 ? 'sample' : 'samples'}',
                  style: const TextStyle(
                    color: indigo,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(color: indigo),
          SizedBox(height: 14),
          Text(
            'Opening your writing library…',
            style: TextStyle(color: muted, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SampleImagePanel extends StatelessWidget {
  final Uint8List imageBytes;

  const _SampleImagePanel({required this.imageBytes});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 420,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6EAF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x081E293B),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InteractiveViewer(
        minScale: 0.8,
        maxScale: 4,
        child: Image.memory(
          imageBytes,
          key: const ValueKey('saved_sample_image'),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _RecognitionPanel extends StatelessWidget {
  final String recognizedText;

  const _RecognitionPanel({required this.recognizedText});

  @override
  Widget build(BuildContext context) {
    final hasText = recognizedText.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6EAF2)),
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
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: indigo, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI Recognition Result',
                  style: TextStyle(color: ink, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasText
                  ? const Color(0xFFF7F8FF)
                  : const Color(0xFFFFF8E8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasText
                    ? const Color(0xFFE4E6FB)
                    : const Color(0xFFF8E4AD),
              ),
            ),
            child: Text(
              hasText ? recognizedText : 'No text was recognized in this sample. You can still view the original handwriting above.',
              key: const ValueKey('saved_sample_recognized_text'),
              style: TextStyle(
                color: hasText ? ink : muted,
                fontSize: 16,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SampleCard extends StatelessWidget {
  final HandwritingSample sample;
  final Uint8List? imageBytes;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final bool compact;

  const _SampleCard({
    required this.sample,
    required this.imageBytes,
    required this.onOpen,
    required this.onDelete,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: compact ? 100 : double.infinity,
        height: compact ? 124 : 158,
        child: imageBytes == null
            ? const ColoredBox(
                color: Color(0xFFF1F2FF),
                child: Icon(Icons.broken_image_outlined, color: muted),
              )
            : Image.memory(
                imageBytes!,
                key: ValueKey('sample_thumbnail_${sample.id}'),
                fit: BoxFit.cover,
              ),
      ),
    );
    final titleAndDetails = Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sample.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _formatSampleDate(sample.createdAt),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: muted, fontSize: 11),
          ),
          if ((sample.recognizedText ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              sample.recognizedText!.trim(),
              maxLines: compact ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: muted, fontSize: 12, height: 1.35),
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Text(
              'No text recognized',
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View sample',
                style: TextStyle(
                  color: indigo,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, color: indigo, size: 14),
            ],
          ),
        ],
      ),
    );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 1,
      child: InkWell(
        key: ValueKey('sample_card_${sample.id}'),
        onTap: onOpen,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8ECF3)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A6366F1),
                blurRadius: 16,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: compact
              ? Row(
                  children: [
                    image,
                    const SizedBox(width: 12),
                    titleAndDetails,
                    IconButton(
                      key: ValueKey('delete_sample_${sample.id}'),
                      tooltip: 'Delete sample',
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: muted,
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    image,
                    const SizedBox(height: 11),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          titleAndDetails,
                          IconButton(
                            key: ValueKey('delete_sample_${sample.id}'),
                            tooltip: 'Delete sample',
                            onPressed: onDelete,
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  final IconData icon;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;
  final bool isError;

  const _MessagePanel({
    required this.icon,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8ECF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x081E293B),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: isError
                  ? const Color(0xFFFFF1F2)
                  : const Color(0xFFFFF4E5),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(icon, color: isError ? pink : amber, size: 40),
          ),
          const SizedBox(height: 15),
          Text(
            isError
                ? 'Your library needs another try'
                : 'Start your collection',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ink,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: muted, fontSize: 14, height: 1.5),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: Icon(isError ? Icons.refresh_rounded : Icons.edit_rounded),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

String _formatSampleDate(DateTime dateTime) {
  final date =
      '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$date · $hour:$minute';
}
