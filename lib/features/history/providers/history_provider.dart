import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';

/// Default history limit (configurable).
const kDefaultHistoryLimit = 100;

/// State for the history screen.
class HistoryScreenState {
  final List<WatchHistoryEntry> entries;
  final bool isLoading;
  final AppFailure? failure;
  final int limit;

  const HistoryScreenState({
    this.entries = const [],
    this.isLoading = true,
    this.failure,
    this.limit = kDefaultHistoryLimit,
  });

  HistoryScreenState copyWith({
    List<WatchHistoryEntry>? entries,
    bool? isLoading,
    AppFailure? failure,
    bool clearFailure = false,
    int? limit,
  }) {
    return HistoryScreenState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure ? null : (failure ?? this.failure),
      limit: limit ?? this.limit,
    );
  }
}

/// Provider for the History Screen state.
final historyScreenProvider =
    StateNotifierProvider<HistoryScreenNotifier, HistoryScreenState>(
  (ref) => HistoryScreenNotifier(ref),
);

/// Notifier that manages watch history state.
class HistoryScreenNotifier extends StateNotifier<HistoryScreenState> {
  final Ref _ref;

  HistoryScreenNotifier(this._ref) : super(const HistoryScreenState()) {
    loadHistory();
  }

  /// Loads recent history entries.
  Future<void> loadHistory() async {
    try {
      final db = _ref.read(databaseProvider);
      final entries = await db.watchHistoryDao.getRecentHistory(
        limit: state.limit,
      );
      state = state.copyWith(
        entries: entries,
        isLoading: false,
        clearFailure: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        failure: DatabaseFailure(
          message: 'Erro ao carregar histórico.',
          originalError: e,
        ),
      );
    }
  }

  /// Records a watch session for a channel.
  Future<void> recordWatch({
    required int channelId,
    required int durationMs,
  }) async {
    try {
      final db = _ref.read(databaseProvider);
      await db.watchHistoryDao.upsertEntry(
        channelId: channelId,
        watchedDurationMs: durationMs,
      );
      await loadHistory();
    } catch (_) {
      // Don't break playback for history errors
    }
  }

  /// Deletes a single history entry.
  Future<void> deleteEntry(int id) async {
    try {
      final db = _ref.read(databaseProvider);
      await db.watchHistoryDao.deleteEntry(id);
      await loadHistory();
    } catch (_) {}
  }

  /// Clears all history.
  Future<void> clearAll() async {
    try {
      final db = _ref.read(databaseProvider);
      await db.watchHistoryDao.clearAll();
      state = state.copyWith(entries: []);
    } catch (_) {}
  }

  /// Trims history to configured limit.
  Future<void> trimHistory() async {
    try {
      final db = _ref.read(databaseProvider);
      await db.watchHistoryDao.trimHistory(state.limit);
      await loadHistory();
    } catch (_) {}
  }

  /// Updates the history limit.
  void setLimit(int newLimit) {
    state = state.copyWith(limit: newLimit);
    trimHistory();
  }
}
