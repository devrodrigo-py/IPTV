import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/focusable_widget.dart';
import 'package:nebula_iptv/features/playlists/providers/playlist_management_provider.dart';
import 'package:nebula_iptv/l10n/app_localizations.dart';

/// Playlists/Sources management screen.
///
/// Shows existing playlists and allows adding new ones via URL or file.
class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(playlistManagementProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(l10n.playlists, style: AppTypography.title),
              const Spacer(),
              FocusableWidget(
                onPressed: () => _showAddDialog(context, ref),
                borderRadius: BorderRadius.circular(8),
                builder: (context, isFocused) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 18, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Adicionar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status message
          if (state.statusMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: state.isError
                    ? AppColors.error.withValues(alpha: 0.1)
                    : AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    state.isError
                        ? Icons.error_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 18,
                    color: state.isError ? AppColors.error : AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.statusMessage!,
                      style: AppTypography.body.copyWith(
                        color: state.isError
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Loading indicator
          if (state.isLoading) ...[
            const LinearProgressIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceElevated,
            ),
            const SizedBox(height: 16),
          ],

          // Playlist list
          Expanded(
            child: state.playlists.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.playlist_add_rounded,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma fonte adicionada',
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Toque em "Adicionar" para importar uma playlist',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: state.playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = state.playlists[index];
                      return _PlaylistTile(
                        name: playlist.name,
                        url: playlist.url,
                        lastSync: playlist.lastSyncAt,
                        onRefresh: () => ref
                            .read(playlistManagementProvider.notifier)
                            .refreshPlaylist(playlist.id),
                        onDelete: () => ref
                            .read(playlistManagementProvider.notifier)
                            .deletePlaylist(playlist.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _AddPlaylistDialog(
        onImportUrl: (name, url) {
          Navigator.of(ctx).pop();
          ref
              .read(playlistManagementProvider.notifier)
              .importFromUrl(name: name, url: url);
        },
        onImportFile: () {
          Navigator.of(ctx).pop();
          ref.read(playlistManagementProvider.notifier).importFromFile();
        },
      ),
    );
  }
}

class _AddPlaylistDialog extends StatefulWidget {
  final void Function(String name, String url) onImportUrl;
  final VoidCallback onImportFile;

  const _AddPlaylistDialog({
    required this.onImportUrl,
    required this.onImportFile,
  });

  @override
  State<_AddPlaylistDialog> createState() => _AddPlaylistDialogState();
}

class _AddPlaylistDialogState extends State<_AddPlaylistDialog> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Adicionar fonte'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                hintText: 'Ex: Minha Playlist',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL da playlist (M3U/M3U8)',
                hintText: 'https://exemplo.com/playlist.m3u',
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: widget.onImportFile,
              icon: const Icon(Icons.file_open_rounded),
              label: const Text('Importar de arquivo'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final url = _urlController.text.trim();
            if (name.isEmpty || url.isEmpty) return;
            widget.onImportUrl(name, url);
          },
          child: const Text('Importar'),
        ),
      ],
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  final String name;
  final String url;
  final DateTime? lastSync;
  final VoidCallback onRefresh;
  final VoidCallback onDelete;

  const _PlaylistTile({
    required this.name,
    required this.url,
    required this.lastSync,
    required this.onRefresh,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.playlist_play_rounded,
            color: AppColors.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.body),
                const SizedBox(height: 2),
                Text(
                  lastSync != null
                      ? 'Atualizado: ${_formatDate(lastSync!)}'
                      : url,
                  style: AppTypography.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            color: AppColors.textSecondary,
            onPressed: onRefresh,
            tooltip: 'Atualizar',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            color: AppColors.textSecondary,
            onPressed: onDelete,
            tooltip: 'Remover',
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
