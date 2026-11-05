import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'lexgo_colors.dart';

class RecognitionResultHeader extends StatelessWidget {
  const RecognitionResultHeader({super.key});

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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6E7FA)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Handwriting Result',
                  style: TextStyle(
                    color: ink,
                    fontSize: 25,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Your page is ready. Take a look at what LexGo could read.',
                  style: TextStyle(
                    color: muted.withValues(alpha: 0.95),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: indigo,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class RecognitionImageCard extends StatelessWidget {
  final Uint8List imageBytes;
  final String title;
  final Key imageKey;
  final String previewErrorMessage;
  final double height;
  final Key? titleKey;

  const RecognitionImageCard({
    super.key,
    required this.imageBytes,
    required this.title,
    required this.imageKey,
    required this.previewErrorMessage,
    required this.height,
    this.titleKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF0FF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.image_outlined,
                  color: indigo,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Original handwriting',
                  style: TextStyle(
                    color: ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Container(
              height: height,
              width: double.infinity,
              color: const Color(0xFFF7F8FC),
              alignment: Alignment.center,
              child: Image.memory(
                imageBytes,
                key: imageKey,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    previewErrorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: muted),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sample title',
            style: TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            key: titleKey,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ink,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class RecognitionTextCard extends StatelessWidget {
  final String recognizedText;
  final String emptyMessage;
  final String successMessage;
  final Key textKey;

  const RecognitionTextCard({
    super.key,
    required this.recognizedText,
    required this.emptyMessage,
    required this.successMessage,
    required this.textKey,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = recognizedText.trim().isNotEmpty;
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
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: indigo),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'AI Recognition Result',
                  style: TextStyle(
                    color: ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
            child: hasText
                ? Text(
                    recognizedText,
                    key: textKey,
                    style: const TextStyle(
                      color: ink,
                      fontSize: 18,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 7,
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            color: Color(0xFFB7791F),
                            size: 19,
                          ),
                          Text(
                            'No text found this time',
                            style: TextStyle(
                              color: ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        emptyMessage,
                        key: textKey,
                        style: const TextStyle(
                          color: muted,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: success,
                size: 18,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  successMessage,
                  style: const TextStyle(
                    color: success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
