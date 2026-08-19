import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';

/// Reusable loading state widget.
///
/// Displays a centered circular progress indicator with the app's
/// primary color.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
        strokeWidth: 3,
      ),
    );
  }
}
