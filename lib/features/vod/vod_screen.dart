import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/empty_view.dart';
import 'package:nebula_iptv/core/widgets/error_view.dart';
import 'package:nebula_iptv/core/widgets/loading_view.dart';
import 'package:nebula_iptv/features/vod/providers/vod_provider.dart';
import 'package:nebula_iptv/features/vod/vod_detail_screen.dart';
import 'package:nebula_iptv/features/vod/widgets/vod_card.dart';
import 'package:nebula_iptv/features/vod/widgets/vod_category_chips.dart';

/// VOD (Movies) browsing screen.
///
/// Displays movies in a responsive grid with category filters and search.
/// Design inspired by Netflix/HBO Max catalog view.
class VodScreen extends ConsumerWidget {
  const VodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vodScreenProvider);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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

        // Category chips
        if (state.categories.isNotEmpty)
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

        const SizedBox(height: 8),

        // Content
        Expanded(
          child: _buildContent(context, state, ref),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    VodScreenState state,
    WidgetRef ref,
  ) {
    if (state.isLoading) {
      return const LoadingView();
    }

    if (state.failure != null) {
      return ErrorView(
        failure: state.failure!,
        onRetry: () => ref.read(vodScreenProvider.notifier).refresh(),
      );
    }

    if (state.filteredMovies.isEmpty) {
      return EmptyView(
        icon: Icons.movie_rounded,
        message: state.searchQuery.isNotEmpty
            ? 'Nenhum filme encontrado para "${state.searchQuery}"'
            : 'Nenhum filme disponível',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive grid: more columns on wider screens
        final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VodDetailScreen(movie: movie),
                  ),
                );
              },
            );
          },
        );
      },
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
