import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/features/shared/widgets/shortcut_context_menu.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/empty_view.dart';
import 'package:nebula_iptv/core/widgets/error_view.dart';
import 'package:nebula_iptv/core/widgets/loading_view.dart';
import 'package:nebula_iptv/features/shared/widgets/content_row.dart';
import 'package:nebula_iptv/features/shared/widgets/hero_banner.dart';
import 'package:nebula_iptv/features/series/providers/series_provider.dart';
import 'package:nebula_iptv/features/shell/providers/shell_navigation_provider.dart';
import 'package:nebula_iptv/features/series/series_detail_screen.dart';
import 'package:nebula_iptv/features/series/widgets/series_card.dart';
import 'package:nebula_iptv/features/vod/widgets/vod_category_chips.dart';

/// Series browsing screen — Netflix-style layout.
///
/// Features a hero banner, horizontal carousels by category,
/// and fallback to grid view when filtered/searching.
class SeriesScreen extends ConsumerStatefulWidget {
  const SeriesScreen({super.key});

  @override
  ConsumerState<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends ConsumerState<SeriesScreen> {
  bool _showGrid = false;
  String? _gridCategory;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(seriesScreenProvider);

    if (state.isLoading) return const LoadingView();

    if (state.failure != null) {
      return ErrorView(
        failure: state.failure!,
        onRetry: () => ref.read(seriesScreenProvider.notifier).refresh(),
      );
    }

    if (state.allSeries.isEmpty) {
      return EmptyView(
        icon: Icons.tv_rounded,
        message: 'Nenhuma série disponível',
        actionLabel: 'Gerenciar Fontes',
        onAction: () => ref.read(shellNavigationProvider.notifier).state = 6,
      );
    }

    // Show grid when searching, filtering by category, or "Ver todos"
    if (_showGrid || state.searchQuery.isNotEmpty || state.selectedCategory != null) {
      return _buildGridView(context, state);
    }

    return _buildNetflixView(context, state);
  }

  String? _formatYear(String? date) {
    if (date == null || date.length < 4) return null;
    return date.substring(0, 4);
  }

  Widget _buildNetflixView(BuildContext context, SeriesScreenState state) {
    // Sort categories by item count (largest first), limit to top 15
    final sortedCategories = state.categorizedSeries.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final topCategories = sortedCategories.take(15).toList();

    final totalItems = 2 + topCategories.length + 1; // Hero + Search + Categories + Spacing

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: totalItems,
      itemBuilder: (context, index) {
        if (index == 0) {
          // Hero Banner
          if (state.heroItems.isNotEmpty) {
            return HeroBanner(
              items: state.heroItems.map((series) {
                return HeroBannerItem(
                  title: series.name,
                  subtitle: series.shortCategory,
                  imageUrl: series.tmdbBackdropUrl ?? series.displayPosterUrl,
                  onPlay: () => _openDetail(context, series),
                  onDetails: () => _openDetail(context, series),
                );
              }).toList(),
            );
          }
          return const SizedBox.shrink();
        }

        if (index == 1) {
          // Search bar
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: TextField(
              onChanged: (query) {
                ref.read(seriesScreenProvider.notifier).search(query);
              },
              style: AppTypography.body,
              decoration: InputDecoration(
                hintText: 'Buscar séries...',
                hintStyle: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
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
                  vertical: 10,
                ),
                isDense: true,
              ),
            ),
          );
        }

        if (index == totalItems - 1) {
          return const SizedBox(height: 32);
        }

        // Category carousels (lazily built)
        final catIndex = index - 2;
        final entry = topCategories[catIndex];
        final categoryName = entry.key;
        final seriesList = entry.value;
        final displaySeries = seriesList.take(20).toList();

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: ContentRow(
            title: categoryName,
            items: displaySeries.map((series) {
              return ContentRowItem(
                title: series.name,
                imageUrl: series.displayPosterUrl,
                subtitle: _formatYear(series.tmdbReleaseDate),
                fallbackIcon: Icons.tv_rounded,
              );
            }).toList(),
            onSeeAll: () {
              setState(() {
                _showGrid = true;
                _gridCategory = seriesList.first.categoryName;
              });
              ref.read(seriesScreenProvider.notifier).filterByCategory(
                seriesList.first.categoryName,
              );
            },
            onItemTap: (itemIdx) {
              _openDetail(context, displaySeries[itemIdx]);
            },
            onItemSecondaryTap: (itemIdx, position) {
              final series = displaySeries[itemIdx];
              showShortcutContextMenu(
                context, ref,
                position: position,
                channelId: series.id,
                channelName: series.name,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildGridView(BuildContext context, SeriesScreenState state) {
    return Column(
      children: [
        // Back button + search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              if (_showGrid)
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.textPrimary),
                  onPressed: () {
                    setState(() {
                      _showGrid = false;
                      _gridCategory = null;
                    });
                    ref.read(seriesScreenProvider.notifier).filterByCategory(null);
                    ref.read(seriesScreenProvider.notifier).search('');
                  },
                ),
              Expanded(
                child: TextField(
                  onChanged: (query) {
                    ref.read(seriesScreenProvider.notifier).search(query);
                  },
                  style: AppTypography.body,
                  decoration: InputDecoration(
                    hintText: 'Buscar séries...',
                    hintStyle: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Category chips
        if (state.categories.isNotEmpty && !_showGrid)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: VodCategoryChips(
              categories: state.categories,
              selectedCategory: state.selectedCategory,
              onSelected: (category) {
                ref.read(seriesScreenProvider.notifier).filterByCategory(category);
              },
            ),
          ),

        if (_showGrid && _gridCategory != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _gridCategory!.split('|').last.trim(),
                style: AppTypography.title,
              ),
            ),
          ),

        const SizedBox(height: 8),

        // Grid
        Expanded(
          child: state.filteredSeries.isEmpty
              ? EmptyView(
                  icon: Icons.tv_rounded,
                  message: state.searchQuery.isNotEmpty
                      ? 'Nenhuma série encontrada para "${state.searchQuery}"'
                      : 'Nenhuma série nesta categoria',
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount =
                        _getCrossAxisCount(constraints.maxWidth);
                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 0.55,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: state.filteredSeries.length,
                      itemBuilder: (context, index) {
                        final series = state.filteredSeries[index];
                        return SeriesCard(
                          series: series,
                          onTap: () => _openDetail(context, series),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _openDetail(BuildContext context, SeriesItem series) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SeriesDetailScreen(series: series),
      ),
    );
  }

  int _getCrossAxisCount(double width) {
    if (width >= 1400) return 7;
    if (width >= 1200) return 6;
    if (width >= 900) return 5;
    if (width >= 700) return 4;
    if (width >= 500) return 3;
    return 2;
  }
}
