import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/l10n/app_localizations.dart';

/// Search bar for the channel browser.
///
/// Uses debounce at the provider level (spec §16).
class ChannelSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const ChannelSearchBar({
    super.key,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TextField(
      onChanged: onChanged,
      style: AppTypography.body,
      decoration: InputDecoration(
        hintText: l10n.search,
        hintStyle: AppTypography.body.copyWith(color: AppColors.textSecondary),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.textSecondary,
          size: 20,
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
