import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/l10n/app_localizations.dart';

/// Error overlay shown when the stream is unavailable.
///
/// Displays after reconnection attempts are exhausted (spec §13.1).
class PlayerErrorOverlay extends StatelessWidget {
  final VoidCallback onRetry;

  const PlayerErrorOverlay({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.signal_wifi_off_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Stream indisponível',
              style: AppTypography.title.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Não foi possível conectar ao canal.',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
