import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/empty_view.dart';
import 'package:nebula_iptv/core/widgets/error_view.dart';
import 'package:nebula_iptv/core/widgets/focusable_widget.dart';
import 'package:nebula_iptv/core/widgets/loading_view.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/features/history/providers/history_provider.dart';
import 'package:nebula_iptv/l10n/app_localizations.dart';

/// History screen displaying recently watched channels.
///
/// Shows watch entries ordered by most recent, with duration info
/// and options to clear individual entries or all history.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(historyScreenProvider);

    if (state.isLoading) return const LoadingView();

    if (state.failure != null) {
      return ErrorView(
        failure: state.failure!,
        onRetry: () => ref.read(historyScreenProvider.notifier).loadHistory(),
      );
    }

    if (state.entries.isEmpty) {
      return const EmptyView(
        icon: Icons.history_rounded,
        message: 'Nenhum canal assistido ainda',
      );
    }

    return Column(
      children: [
        // Header with clear button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(l10n.history, style: AppTypography.title),
              const Spacer(),
              FocusableWidget(
                onPressed: () => _confirmClearAll(context, ref),
                borderRadius: BorderRadius.circular(8),
                builder: (context, isFocused) => Text(
                  'Limpar tudo',
                  style: AppTypography.label.copyWith(
                    color:
                        isFocused ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // History list
        Expanded(
          child: ListView.builder(
            itemCount: state.entries.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final entry = state.entries[index];
              return _HistoryTile(
                entry: entry,
                onTap: () {
                  // Navigate to player with this channel (Phase 6 integration)
                },
                onDelete: () {
                  ref.read(historyScreenProvider.notifier).deleteEntry(
                        entry.id,
                      );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Limpar histórico'),
        content: const Text('Deseja remover todo o histórico de reprodução?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(historyScreenProvider.notifier).clearAll();
              Navigator.of(ctx).pop();
            },
            child: const Text(
              'Limpar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single history entry tile.
class _HistoryTile extends StatelessWidget {
  final WatchHistoryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryTile({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: FocusableWidget(
        onPressed: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        builder: (context, isFocused) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isFocused ? AppColors.surfaceElevated : AppColors.surface,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.play_circle_outline_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Canal #${entry.channelId}',
                      style: AppTypography.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDuration(entry.watchedDurationMs),
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              Text(
                _formatTimeAgo(entry.lastWatchedAt),
                style: AppTypography.caption,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                onPressed: onDelete,
                splashRadius: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int ms) {
    final minutes = ms ~/ 60000;
    if (minutes < 1) return 'Menos de 1 min';
    if (minutes < 60) return '$minutes min assistidos';
    final hours = minutes ~/ 60;
    final remainingMin = minutes % 60;
    return '${hours}h ${remainingMin}min assistidos';
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min atrás';
    if (diff.inHours < 24) return '${diff.inHours}h atrás';
    if (diff.inDays < 7) return '${diff.inDays}d atrás';
    return '${date.day}/${date.month}';
  }
}
