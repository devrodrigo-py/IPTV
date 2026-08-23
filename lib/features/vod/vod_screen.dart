import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/empty_view.dart';
import 'package:nebula_iptv/core/widgets/error_view.dart';
import 'package:nebula_iptv/core/widgets/loading_view.dart';
import 'package:nebula_iptv/features/shared/widgets/content_row.dart';
import 'package:nebula_iptv/features/shared/widgets/hero_banner.dart';
import 'package:nebula_iptv/features/vod/providers/vod_provider.dart';
import 'package:nebula_iptv/features/vod/vod_detail_screen.dart';
import 'package:nebula_iptv/features/vod/widgets/vod_card.dart';
import 'package:nebula_iptv/features/vod/widgets/vod_category_chips.dart';

/// VOD (Movies) browsing screen — Netflix-style layout.
///
/// Features a hero banner, horizontal carousels by category,
/// and fallback to grid view when filtered/searching.
class VodScreen extends ConsumerStatefulWidget {
  const VodScreen({super.key});

  @override
  ConsumerState<VodScreen> createState() => _VodScreenState();
}

class _VodScreenState extends ConsumerState<VodScreen> {
  bool _showGrid = false;
  String? _gridCategory;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vodScreenProvider);

    if (state.isLoading) return const LoadingView();

    if (state.failure != null) {
      return ErrorView(
        failure: state.failure!,
        onRetry: () => ref.read(vodScreenProvider.notifier).refresh(),
      );
    }

    if (state.allMovies.isEmpty) {
      return const EmptyView(
        icon: Icons.movie_rounded,
        message: 'Nenhum filme disponível',
      );
    }

    // Show grid when searching, filtering by category, or "Ver todos"
    if (_showGrid || state.searchQuery.isNotEmpty || state.selectedCategory != null) {
      return _buildGridView(context, state);
    }

    return _buildNetflixView(context, state);
  }

  Widget _buildNetflixView(BuildContext context, VodScreenState state) {
    // Sort categories by item count (largest first), limit to top 15
    final sortedCategories = state.categorizedMovies.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final topCategories = sortedCategories.take(15).toList();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Hero Banner
        if (state.heroItems.isNotEmpty)
          HeroBanner(
            items: state.heroItems.map((movie) {
              return HeroBannerItem(
                title: movie.name,
                subtitle: movie.shortCategory,
                imageUrl: movie.displayPosterUrl,
                onPlay: () => _openDetail(context, movie),
                onDetails: () => _openDetail(context, movie),
              );
            }).toList(),
          ),

        const SizedBox(height: 16),

        // Search bar (compact)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: (query) {
              ref.read(vodScreenProvider.notifier).search(query);
            },
            style: AppTypography.body,
            decoration: InputDecoration(
              hintText: 'Buscar filmes...',
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
        ),

        const SizedBox(height: 20),

        // Category carousels
        ...topCategories.map((entry) {
          final categoryName = entry.key;
          final movies = entry.value;
          // Limit to 20 per row for performance
          final displayMovies = movies.take(20).toList();

          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: ContentRow(
              title: categoryName,
              items: displayMovies.map((movie) {
                return ContentRowItem(
                  title: movie.name,
                  imageUrl: movie.displayPosterUrl,
                  subtitle: movie.tmdbReleaseDate?.substring(0, 4),
                  fallbackIcon: Icons.movie_rounded,
                );
              }).toList(),
              onSeeAll: () {
                setState(() {
                  _showGrid = true;
                  _gridCategory = movies.first.categoryName;
                });
                ref.read(vodScreenProvider.notifier).filterByCategory(
                  movies.first.categoryName,
                );
              },
              onItemTap: (index) {
                _openDetail(context, displayMovies[index]);
              },
            ),
          );
        }),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildGridView(BuildContext context, VodScreenState state) {
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
                    ref.read(vodScreenProvider.notifier).filterByCategory(null);
                    ref.read(vodScreenProvider.notifier).search('');
                  },
                ),
              Expanded(
                child: TextField(
                  onChanged: (query) {
                    ref.read(vodScreenProvider.notifier).search(query);
                  },
                  style: AppTypography.body,
                  decoration: InputDecoration(
                    hintText: 'Buscar filmes...',
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
                ref.read(vodScreenProvider.notifier).filterByCategory(category);
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
          child: state.filteredMovies.isEmpty
              ? EmptyView(
                  icon: Icons.movie_rounded,
                  message: state.searchQuery.isNotEmpty
                      ? 'Nenhum filme encontrado para "${state.searchQuery}"'
                      : 'Nenhum filme nesta categoria',
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
                        childAspectRatio: 0.6,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: state.filteredMovies.length,
                      itemBuilder: (context, index) {
                        final movie = state.filteredMovies[index];
                        return VodCard(
                          movie: movie,
                          onTap: () => _openDetail(context, movie),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _openDetail(BuildContext context, VodItem movie) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VodDetailScreen(movie: movie),
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
