import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/empty_view.dart';
import 'package:nebula_iptv/core/widgets/error_view.dart';
import 'package:nebula_iptv/core/widgets/loading_view.dart';
import 'package:nebula_iptv/features/series/providers/series_provider.dart';
import 'package:nebula_iptv/features/series/series_detail_screen.dart';
import 'package:nebula_iptv/features/series/widgets/series_card.dart';
import 'package:nebula_iptv/features/vod/widgets/vod_category_chips.dart';

/// Series browsing screen.
///
/// Displays series in a responsive grid with category filters and search.
class SeriesScreen extends ConsumerWidget {
  const SeriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(seriesScreenProvider);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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

        // Category chips
        if (state.categories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: VodCategoryChips(
              categories: state.categories,
              selectedCategory: state.selectedCategory,
              onSelected: (category) {
                ref
                    .read(seriesScreenProvider.notifier)
                    .filterByCategory(category);
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
    SeriesScreenState state,
    WidgetRef ref,
  ) {
    if (state.isLoading) {
      return const LoadingView();
    }

    if (state.failure != null) {
      return ErrorView(
        failure: state.failure!,
        onRetry: () => ref.read(seriesScreenProvider.notifier).refresh(),
      );
    }

    if (state.filteredSeries.isEmpty) {
      return EmptyView(
        icon: Icons.tv_rounded,
        message: state.searchQuery.isNotEmpty
            ? 'Nenhuma série encontrada para "${state.searchQuery}"'
            : 'Nenhuma série disponível',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SeriesDetailScreen(series: series),
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
