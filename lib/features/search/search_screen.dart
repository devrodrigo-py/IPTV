import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/empty_view.dart';
import 'package:nebula_iptv/core/widgets/loading_view.dart';
import 'package:nebula_iptv/core/widgets/remote_text_field.dart';
import 'package:nebula_iptv/domain/services/watch_tracking_service.dart';
import 'package:nebula_iptv/features/player/player_screen.dart';
import 'package:nebula_iptv/features/search/providers/search_provider.dart';
import 'package:nebula_iptv/features/search/widgets/search_result_tile.dart';
import 'package:nebula_iptv/features/series/providers/series_provider.dart'
    show SeriesItem;
import 'package:nebula_iptv/features/series/series_detail_screen.dart';

/// Global search screen — fuzzy search across channels, films, and series.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus the search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: RemoteTextField(
          controller: _controller,
          focusNode: _focusNode,
          style: AppTypography.body,
          decoration: InputDecoration(
            hintText: 'Buscar canais, filmes, séries...',
            hintStyle:
                AppTypography.body.copyWith(color: AppColors.textSecondary),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            ref.read(searchProvider.notifier).updateQuery(value);
          },
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded,
                  color: AppColors.textSecondary),
              onPressed: () {
                _controller.clear();
                ref.read(searchProvider.notifier).updateQuery('');
              },
            ),
        ],
      ),
      body: _buildBody(searchState),
    );
  }

  Widget _buildBody(SearchState searchState) {
    if (searchState.query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'O que deseja assistir?',
              style:
                  AppTypography.body.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (searchState.isSearching) return const LoadingView();
    if (searchState.errorMessage != null) {
      return EmptyView(
      message: searchState.errorMessage!, isError: true, actionLabel: 'Tentar novamente',
      onAction: () => ref.read(searchProvider.notifier).updateQuery(searchState.query));
    }
    final results = searchState.results;
    if (results == null || results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum resultado para "${searchState.query}"',
              style:
                  AppTypography.body.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final entries = <({String? heading, int count, SearchResultItem? item})>[];
    for (final group in [(title: 'Canais', items: results.channels), (title: 'Filmes', items: results.vod), (title: 'Séries', items: results.series)]) {
      if (group.items.isEmpty) continue;
      entries.add((heading: group.title, count: group.items.length, item: null));
      entries.addAll(group.items.map((item) => (heading: null, count: 0, item: item)));
    }
    return ListView.builder(scrollCacheExtent: ScrollCacheExtent.pixels(500), padding: const EdgeInsets.only(bottom: 32),
      itemCount: entries.length, itemBuilder: (context, index) {
        final entry = entries[index];
        if (entry.heading != null) return _buildSectionHeader(entry.heading!, entry.count);
        return SearchResultTile(item: entry.item!, onTap: () => _openItem(entry.item!));
      });
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Text(
            title,
            style: AppTypography.title.copyWith(fontSize: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openItem(SearchResultItem item) {
    if (item.isSeries) {
      final seriesItem = SeriesItem(
        id: item.id,
        playlistId: item.playlistId,
        name: item.name,
        coverUrl: item.logoUrl,
        categoryName: item.groupName,
        sourceId: item.sourceId,
      );
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SeriesDetailScreen(series: seriesItem),
        ),
      );
    } else {
      if (item.streamUrl == null || item.streamUrl!.isEmpty) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PlayerScreen(
            channelName: item.name,
            streamUrl: item.streamUrl!,
            logoUrl: item.logoUrl,
            contentInfo: WatchContentInfo(
              channelId: item.id,
              name: item.name,
              contentType: item.isVod ? 'vod' : 'live',
              thumbnailUrl: item.logoUrl,
            ),
          ),
        ),
      );
    }
  }
}
