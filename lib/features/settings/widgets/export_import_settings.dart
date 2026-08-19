import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/focusable_widget.dart';

/// Settings widget for export/import of user data (spec §30).
class ExportImportSettings extends StatelessWidget {
  final VoidCallback onExport;
  final VoidCallback onImport;

  const ExportImportSettings({
    super.key,
    required this.onExport,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FocusableWidget(
          onPressed: onExport,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          builder: (context, isFocused) => const Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(
                  Icons.upload_rounded,
                  size: 22,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Exportar dados', style: AppTypography.body),
                      const SizedBox(height: 2),
                      const Text(
                        'Playlists, favoritos e configurações',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        FocusableWidget(
          onPressed: onImport,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          builder: (context, isFocused) => const Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(
                  Icons.download_rounded,
                  size: 22,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Importar dados', style: AppTypography.body),
                      const SizedBox(height: 2),
                      const Text(
                        'Restaurar de arquivo JSON',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
