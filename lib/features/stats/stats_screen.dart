import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/focusable_widget.dart';
import 'package:nebula_iptv/core/widgets/nebula_cached_image.dart';
import 'package:nebula_iptv/features/shared/widgets/content_row.dart';
import 'package:nebula_iptv/features/stats/providers/stats_provider.dart';
import 'package:nebula_iptv/features/wrapped/wrapped_screen.dart';

/// Statistics dashboard screen (Etapa 7).
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          'Erro ao carregar estatísticas',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
      ),
      data: (stats) => _buildContent(context, stats),
    );
  }

  Widget _buildContent(BuildContext context, StatsData stats) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Nebula Wrapped button
        _buildWrappedCard(context),
        const SizedBox(height: 24),

        // Header stat cards
        _buildStatCards(stats),
        const SizedBox(height: 32),

        // Daily watch chart
        _buildSectionTitle('Tempo assistido (últimos 7 dias)'),
        const SizedBox(height: 16),
        _buildDailyChart(stats.dailyWatch),
        const SizedBox(height: 32),

        // Content type distribution
        if (stats.contentTypeSplit.isNotEmpty) ...[
          _buildSectionTitle('Distribuição por tipo'),
          const SizedBox(height: 16),
          _buildContentTypeBars(stats),
          const SizedBox(height: 32),
        ],

        // Top 10 most watched
        _buildSectionTitle('Top 10 mais assistidos'),
        const SizedBox(height: 16),
        _buildTopWatched(stats),
        const SizedBox(height: 32),

        // Category distribution
        if (stats.categoryDistribution.isNotEmpty) ...[
          _buildSectionTitle('Categorias mais assistidas'),
          const SizedBox(height: 16),
          _buildCategoryList(stats.categoryDistribution),
          const SizedBox(height: 32),
        ],

        // Top rated carousel
        if (stats.topRated.isNotEmpty) ...[
          _buildSectionTitle('⭐ Seus mais bem avaliados'),
          const SizedBox(height: 16),
          _buildTopRatedRow(stats.topRated),
        ],

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildWrappedCard(BuildContext context) {
    return FocusableWidget(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const WrappedScreen()),
        );
      },
      builder: (context, focused) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.nebulaViolet, AppColors.solarCoral],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.nebulaViolet.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded,
                size: 36, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🎬 Nebula Wrapped',
                      style: AppTypography.title.copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Descubra seus hábitos de consumo',
                      style: AppTypography.caption
                          .copyWith(color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 18, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards(StatsData stats) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _StatCard(
            icon: Icons.access_time_rounded,
            label: 'Tempo total',
            value: stats.totalWatchFormatted,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          _StatCard(
            icon: Icons.play_circle_outline_rounded,
            label: 'Sessões',
            value: stats.totalSessions.toString(),
            color: AppColors.secondary,
          ),
          const SizedBox(width: 12),
          _StatCard(
            icon: Icons.local_fire_department_rounded,
            label: 'Streak',
            value: '${stats.streak} dias',
            color: Colors.orange,
          ),
          const SizedBox(width: 12),
          _StatCard(
            icon: Icons.star_rounded,
            label: 'Avaliações',
            value: stats.ratedCount.toString(),
            color: Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyChart(List<Map<String, dynamic>> dailyWatch) {
    if (dailyWatch.isEmpty) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Nenhum dado de visualização ainda',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    // Find max for scaling
    final maxMs = dailyWatch
        .map((d) => (d['total_ms'] as int?) ?? 0)
        .reduce((a, b) => a > b ? a : b);
    const maxHeight = 120.0;

    final dayNames = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        height: 180,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: dailyWatch.map((day) {
            final ms = (day['total_ms'] as int?) ?? 0;
            final height = maxMs > 0 ? (ms / maxMs * maxHeight) : 0.0;
            final date = DateTime.tryParse(day['date'] as String? ?? '');
            final dayLabel = date != null ? dayNames[date.weekday % 7] : '?';
            final timeLabel = _formatMs(ms);

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Time label
                    Text(
                      timeLabel,
                      style: AppTypography.caption.copyWith(fontSize: 9),
                    ),
                    const SizedBox(height: 4),
                    // Bar
                    Container(
                      height: height.clamp(4.0, maxHeight),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Day label
                    Text(
                      dayLabel,
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildContentTypeBars(StatsData stats) {
    final total = stats.contentTypeSplit.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final typeLabels = {
      'live': 'Canais ao vivo',
      'vod': 'Filmes',
      'series': 'Séries'
    };
    final typeColors = {
      'live': AppColors.primary,
      'vod': Colors.teal,
      'series': Colors.orange,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: stats.contentTypeSplit.entries.map((entry) {
          final percent = entry.value / total;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      typeLabels[entry.key] ?? entry.key,
                      style: AppTypography.body.copyWith(fontSize: 13),
                    ),
                    Text(
                      '${(percent * 100).toStringAsFixed(0)}% • ${_formatMs(entry.value)}',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent,
                    backgroundColor: AppColors.divider,
                    color: typeColors[entry.key] ?? AppColors.primary,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopWatched(StatsData stats) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: 'Canais'),
                Tab(text: 'Filmes'),
                Tab(text: 'Séries'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 400,
            child: TabBarView(
              children: [
                _buildTopList(stats.topLive),
                _buildTopList(stats.topVod),
                _buildTopList(stats.topSeries),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Nenhum dado ainda',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final maxMs = (items.first['total_ms'] as int?) ?? 1;

    return ListView.builder(
      itemCount: items.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final item = items[index];
        final name = item['name'] as String? ?? 'Desconhecido';
        final logoUrl = item['logo_url'] as String?;
        final totalMs = (item['total_ms'] as int?) ?? 0;
        final sessions = (item['sessions'] as int?) ?? 0;
        final progress = maxMs > 0 ? totalMs / maxMs : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              // Rank number
              SizedBox(
                width: 28,
                child: Text(
                  '${index + 1}',
                  style: AppTypography.title.copyWith(
                    color:
                        index < 3 ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: logoUrl != null && logoUrl.isNotEmpty
                      ? NebulaCachedImage(
                          imageUrl: logoUrl,
                          fit: BoxFit.cover,
                          cacheWidth: 96,
                          cacheHeight: 96,
                          placeholder: _thumbPlaceholder(),
                        )
                      : _thumbPlaceholder(),
                ),
              ),
              const SizedBox(width: 12),
              // Name + stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTypography.body.copyWith(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _formatMs(totalMs),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$sessions sessões',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.divider,
                        color: AppColors.primary,
                        minHeight: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryList(List<Map<String, dynamic>> categories) {
    final total = categories.fold<int>(
      0,
      (sum, c) => sum + ((c['total_ms'] as int?) ?? 0),
    );
    if (total == 0) return const SizedBox.shrink();

    final colors = [
      AppColors.primary,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.green,
      Colors.purple,
      Colors.blue,
      Colors.red,
      Colors.cyan,
      Colors.amber,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: categories.asMap().entries.map((entry) {
          final index = entry.key;
          final cat = entry.value;
          final name = cat['category'] as String? ?? 'Outros';
          final ms = (cat['total_ms'] as int?) ?? 0;
          final percent = ms / total;
          // Extract short name (after "Canais | " or "Filmes | " etc)
          final shortName =
              name.contains('|') ? name.split('|').last.trim() : name;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    shortName,
                    style: AppTypography.body.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${(percent * 100).toStringAsFixed(0)}%',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatMs(ms),
                  style: AppTypography.caption,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopRatedRow(List<Map<String, dynamic>> items) {
    final rowItems = items.map((item) {
      return ContentRowItem(
        title: item['name'] as String? ?? '',
        imageUrl: item['logo_url'] as String?,
        subtitle: '⭐ ${(item['rating'] as num?)?.toStringAsFixed(1) ?? ''}',
      );
    }).toList();

    return ContentRow(
      title: '',
      items: rowItems,
      onItemTap: (_) {},
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTypography.title);
  }

  Widget _thumbPlaceholder() {
    return Container(
      color: AppColors.surfaceElevated,
      child: const Icon(Icons.tv_rounded,
          size: 20, color: AppColors.textSecondary),
    );
  }

  String _formatMs(int ms) {
    final hours = ms ~/ 3600000;
    final minutes = (ms % 3600000) ~/ 60000;
    if (hours > 0) return '${hours}h ${minutes}min';
    if (minutes > 0) return '${minutes}min';
    return '${ms ~/ 1000}s';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTypography.headline.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
