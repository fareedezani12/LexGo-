import 'package:flutter/material.dart';

import 'lexgo_colors.dart';

/// Shared back navigation button used by LexGo feature pages.
class LexGoBackButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback? onPressed;

  const LexGoBackButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: const Icon(Icons.arrow_back_rounded, size: 21),
      style: IconButton.styleFrom(
        fixedSize: const Size(44, 44),
        padding: EdgeInsets.zero,
        backgroundColor: Colors.white,
        foregroundColor: ink,
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
