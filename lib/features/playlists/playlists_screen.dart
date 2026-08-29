import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
              if (Navigator.of(context).canPop()) ...[
                IconButton(
                  tooltip: 'Voltar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 4),
              ],
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
        onImportXtream: (name, serverUrl, username, password) {
          Navigator.of(ctx).pop();
          ref.read(playlistManagementProvider.notifier).importFromXtream(
                name: name,
                serverUrl: serverUrl,
                username: username,
                password: password,
              );
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
  final void Function(String name, String serverUrl, String username, String password) onImportXtream;
  final VoidCallback onImportFile;

  const _AddPlaylistDialog({
    required this.onImportUrl,
    required this.onImportXtream,
    required this.onImportFile,
  });

  @override
  State<_AddPlaylistDialog> createState() => _AddPlaylistDialogState();
}

class _AddPlaylistDialogState extends State<_AddPlaylistDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _xtreamNameController = TextEditingController();
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // Focus nodes for TV remote / keyboard navigation
  final _xtreamNameFocus = FocusNode(debugLabel: 'xtreamName');
  final _serverUrlFocus = FocusNode(debugLabel: 'serverUrl');
  final _usernameFocus = FocusNode(debugLabel: 'username');
  final _passwordFocus = FocusNode(debugLabel: 'password');

  final _m3uNameFocus = FocusNode(debugLabel: 'm3uName');
  final _urlFocus = FocusNode(debugLabel: 'm3uUrl');
  final _fileButtonFocus = FocusNode(debugLabel: 'fileButton');

  final _cancelButtonFocus = FocusNode(debugLabel: 'cancelButton');
  final _importButtonFocus = FocusNode(debugLabel: 'importButton');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _xtreamNameFocus.onKeyEvent = (node, event) =>
        _handleFieldKeyEvent(_serverUrlFocus, null, event);
    _serverUrlFocus.onKeyEvent = (node, event) =>
        _handleFieldKeyEvent(_usernameFocus, _xtreamNameFocus, event);
    _usernameFocus.onKeyEvent = (node, event) =>
        _handleFieldKeyEvent(_passwordFocus, _serverUrlFocus, event);
    _passwordFocus.onKeyEvent = (node, event) =>
        _handleFieldKeyEvent(_importButtonFocus, _usernameFocus, event);

    _m3uNameFocus.onKeyEvent = (node, event) =>
        _handleFieldKeyEvent(_urlFocus, null, event);
    _urlFocus.onKeyEvent = (node, event) =>
        _handleFieldKeyEvent(_fileButtonFocus, _m3uNameFocus, event);
    _fileButtonFocus.onKeyEvent = (node, event) =>
        _handleFieldKeyEvent(_importButtonFocus, _urlFocus, event);
  }

  KeyEventResult _handleFieldKeyEvent(FocusNode nextFocus, FocusNode? prevFocus, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        nextFocus.requestFocus();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp && prevFocus != null) {
        prevFocus.requestFocus();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _xtreamNameController.dispose();
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();

    _xtreamNameFocus.dispose();
    _serverUrlFocus.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _m3uNameFocus.dispose();
    _urlFocus.dispose();
    _fileButtonFocus.dispose();
    _cancelButtonFocus.dispose();
    _importButtonFocus.dispose();

    _tabController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_tabController.index == 0) {
      // Xtream
      final name = _xtreamNameController.text.trim();
      final serverUrl = _serverUrlController.text.trim();
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();
      if (name.isEmpty || serverUrl.isEmpty ||
          username.isEmpty || password.isEmpty) return;
      widget.onImportXtream(name, serverUrl, username, password);
    } else {
      // M3U
      final name = _nameController.text.trim();
      final url = _urlController.text.trim();
      if (name.isEmpty || url.isEmpty) return;
      widget.onImportUrl(name, url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Adicionar fonte'),
      content: SizedBox(
        width: 400,
        height: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Xtream Codes'),
                Tab(text: 'M3U / URL'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Xtream Codes
                  SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _xtreamNameController,
                          focusNode: _xtreamNameFocus,
                          autofocus: true,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _serverUrlFocus.requestFocus(),
                          decoration: const InputDecoration(
                            labelText: 'Nome',
                            hintText: 'Ex: Minha IPTV',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _serverUrlController,
                          focusNode: _serverUrlFocus,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.url,
                          onSubmitted: (_) => _usernameFocus.requestFocus(),
                          decoration: const InputDecoration(
                            labelText: 'URL do servidor',
                            hintText: 'http://servidor.com',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _usernameController,
                          focusNode: _usernameFocus,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _passwordFocus.requestFocus(),
                          decoration: const InputDecoration(
                            labelText: 'Usuário',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          decoration: const InputDecoration(
                            labelText: 'Senha',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tab 2: M3U URL
                  SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _nameController,
                          focusNode: _m3uNameFocus,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _urlFocus.requestFocus(),
                          decoration: const InputDecoration(
                            labelText: 'Nome',
                            hintText: 'Ex: Minha Playlist',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _urlController,
                          focusNode: _urlFocus,
                          textInputAction: TextInputAction.done,
                          keyboardType: TextInputType.url,
                          onSubmitted: (_) => _submit(),
                          decoration: const InputDecoration(
                            labelText: 'URL da playlist (M3U/M3U8)',
                            hintText: 'https://exemplo.com/playlist.m3u',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          focusNode: _fileButtonFocus,
                          onPressed: widget.onImportFile,
                          icon: const Icon(Icons.file_open_rounded),
                          label: const Text('Importar de arquivo'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          focusNode: _cancelButtonFocus,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          focusNode: _importButtonFocus,
          onPressed: _submit,
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
