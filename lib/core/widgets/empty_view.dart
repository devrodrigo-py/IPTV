import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/l10n/app_localizations.dart';

/// Reusable empty state widget.
///
/// Displays a friendly message when there is no content to show, with an
/// optional action button (CTA).
///
/// Two variants:
/// - Empty (default): icon in `auroraTeal` + CTA de ação (ex.: "Ver Canais").
/// - Error (`isError: true`): icon in `solarCoral` + botão "Tentar
///   novamente" — dá um caminho de recuperação em vez de beco sem saída.
class EmptyView extends StatelessWidget {
  final String? message;
  final IconData icon;

  /// Rótulo do botão de ação (ex.: "Ver Canais", "Tentar novamente").
  final String? actionLabel;

  /// Callback do botão de ação. O botão só aparece se [actionLabel] e
  /// [onAction] forem fornecidos.
  final VoidCallback? onAction;

  /// Variante de erro: ícone em `solarCoral`, para falhas (rede, stream).
  /// A variante padrão (vazia) usa `auroraTeal`.
  final bool isError;

  const EmptyView({
    super.key,
    this.message,
    this.icon = Icons.inbox_rounded,
    this.actionLabel,
    this.onAction,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accentColor = isError ? AppColors.solarCoral : AppColors.auroraTeal;
    final showAction = actionLabel != null && onAction != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.12),
              ),
              child: Icon(
                icon,
                size: 40,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message ?? l10n.noContent,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (showAction) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  // Texto escuro (void950) sobre teal/coral garante contraste
                  // em ambos os accents.
                  foregroundColor: AppColors.void950,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: Icon(
                  isError ? Icons.refresh_rounded : Icons.arrow_forward_rounded,
                  size: 18,
                ),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
