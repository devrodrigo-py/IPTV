import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/network/dio_client.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/datasources/m3u/m3u_datasource.dart';
import 'package:nebula_iptv/data/repositories/playlist_import_repository.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';
import 'package:nebula_iptv/features/playlists/widgets/playlist_file_picker.dart';

/// State for playlist management screen.
class PlaylistManagementState {
  final List<Playlist> playlists;
  final bool isLoading;
  final String? statusMessage;
  final bool isError;

  const PlaylistManagementState({
    this.playlists = const [],
    this.isLoading = false,
    this.statusMessage,
    this.isError = false,
  });

  PlaylistManagementState copyWith({
    List<Playlist>? playlists,
    bool? isLoading,
    String? statusMessage,
    bool clearStatus = false,
    bool? isError,
  }) {
    return PlaylistManagementState(
      playlists: playlists ?? this.playlists,
      isLoading: isLoading ?? this.isLoading,
      statusMessage: clearStatus ? null : (statusMessage ?? this.statusMessage),
      isError: isError ?? this.isError,
    );
  }
}

/// Provider for playlist management.
final playlistManagementProvider = StateNotifierProvider<
    PlaylistManagementNotifier, PlaylistManagementState>(
  (ref) => PlaylistManagementNotifier(ref),
);

/// Manages playlist CRUD operations.
class PlaylistManagementNotifier
    extends StateNotifier<PlaylistManagementState> {
  final Ref _ref;
  late final PlaylistImportRepository _importRepo;
  late final PlaylistFilePicker _filePicker;

  PlaylistManagementNotifier(this._ref)
      : super(const PlaylistManagementState()) {
    final db = _ref.read(databaseProvider);
    _importRepo = PlaylistImportRepository(
      db: db,
      m3uDataSource: M3uDataSource(client: DioClient()),
    );
    _filePicker = PlaylistFilePicker();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final db = _ref.read(databaseProvider);
    final playlists = await db.playlistsDao.getAllPlaylists();
    state = state.copyWith(playlists: playlists);
  }

  /// Imports a playlist from URL.
  Future<void> importFromUrl({
    required String name,
    required String url,
  }) async {
    state = state.copyWith(isLoading: true, clearStatus: true);

    final result = await _importRepo.importFromUrl(
      name: name,
      url: url,
    );

    result.when(
      success: (data) {
        state = state.copyWith(
          isLoading: false,
          statusMessage:
              '✓ Importado: ${data.channelsAdded} canais de "$name"',
          isError: false,
        );
        _loadPlaylists();
        // Refresh channels screen
        _ref.read(channelsScreenProvider.notifier).refresh();
      },
      failure: (f) {
        state = state.copyWith(
          isLoading: false,
          statusMessage: f.message,
          isError: true,
        );
      },
    );
  }

  /// Imports a playlist from a file (uses file picker).
  Future<void> importFromFile() async {
    final pickResult = await _filePicker.pickPlaylistFile();

    await pickResult.when(
      success: (file) async {
        state = state.copyWith(isLoading: true, clearStatus: true);

        final result = await _importRepo.importFromFile(
          name: file.fileName.replaceAll(RegExp(r'\.\w+$'), ''),
          filePath: file.content, // readFromContent expects content string
        );

        result.when(
          success: (data) {
            state = state.copyWith(
              isLoading: false,
              statusMessage:
                  '✓ Importado: ${data.channelsAdded} canais de "${file.fileName}"',
              isError: false,
            );
            _loadPlaylists();
            _ref.read(channelsScreenProvider.notifier).refresh();
          },
          failure: (f) {
            state = state.copyWith(
              isLoading: false,
              statusMessage: f.message,
              isError: true,
            );
          },
        );
      },
      failure: (f) {
        if (f.message != 'Nenhum arquivo selecionado.') {
          state = state.copyWith(
            statusMessage: f.message,
            isError: true,
          );
        }
      },
    );
  }

  /// Refreshes a playlist (re-fetches from source).
  Future<void> refreshPlaylist(int playlistId) async {
    state = state.copyWith(isLoading: true, clearStatus: true);

    final result = await _importRepo.refreshPlaylist(playlistId);

    result.when(
      success: (data) {
        state = state.copyWith(
          isLoading: false,
          statusMessage:
              '✓ Atualizado: +${data.channelsAdded} novos, '
              '${data.channelsDeactivated} removidos',
          isError: false,
        );
        _loadPlaylists();
        _ref.read(channelsScreenProvider.notifier).refresh();
      },
      failure: (f) {
        state = state.copyWith(
          isLoading: false,
          statusMessage: f.message,
          isError: true,
        );
      },
    );
  }

  /// Deletes a playlist.
  Future<void> deletePlaylist(int playlistId) async {
    final db = _ref.read(databaseProvider);
    await db.playlistsDao.deletePlaylist(playlistId);
    await _loadPlaylists();
    _ref.read(channelsScreenProvider.notifier).refresh();
    state = state.copyWith(
      statusMessage: 'Fonte removida',
      isError: false,
    );
  }
}
