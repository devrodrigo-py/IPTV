import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/domain/services/wrapped_service.dart';

/// Nebula Wrapped — Spotify Wrapped-style yearly review.
/// Full-screen stories experience with animated stats slides.
class WrappedScreen extends ConsumerStatefulWidget {
  const WrappedScreen({super.key});

  @override
  ConsumerState<WrappedScreen> createState() => _WrappedScreenState();
}

class _WrappedScreenState extends ConsumerState<WrappedScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 7) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wrappedAsync = ref.watch(wrappedProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: wrappedAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Assista mais conteúdo para gerar seu Wrapped!',
                  style: AppTypography.body.copyWith(color: Colors.white70)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
        data: (data) => _buildWrapped(data),
      ),
    );
  }

  Widget _buildWrapped(WrappedData data) {
    final slides = _buildSlides(data);

    return Stack(
      children: [
        // Page view with stories
        GestureDetector(
          onTapUp: (details) {
            final width = MediaQuery.of(context).size.width;
            if (details.globalPosition.dx > width / 2) {
              _nextPage();
            } else {
              _prevPage();
            }
          },
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemCount: slides.length,
            itemBuilder: (context, index) => slides[index],
          ),
        ),

        // Progress dots at top
        Positioned(
          top: 50,
          left: 16,
          right: 16,
          child: Row(
            children: List.generate(slides.length, (i) {
              return Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: i <= _currentPage
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ),

        // Close button
        Positioned(
          top: 60,
          right: 16,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSlides(WrappedData data) {
    return [
      // Slide 1: Intro
      _WrappedSlide(
        gradient: const [Color(0xFF6C63FF), Color(0xFF3F37C9)],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.blur_on_rounded, size: 80, color: Colors.white),
            const SizedBox(height: 24),
            Text(
              'Nebula\nWrapped',
              style: AppTypography.display.copyWith(
                color: Colors.white,
                fontSize: 48,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '2026',
              style: AppTypography.headline.copyWith(
                color: Colors.white70,
                fontSize: 32,
              ),
            ),
          ],
        ),
      ),

      // Slide 2: Total hours
      _WrappedSlide(
        gradient: const [Color(0xFF7B2FF7), Color(0xFFF107A3)],
        child: _AnimatedStat(
          icon: Icons.schedule_rounded,
          label: 'Você assistiu',
          value: '${data.totalHoursWatched}h ${data.totalMinutesRemainder}min',
          subtitle: '${data.totalSessions} sessões',
        ),
      ),

      // Slide 3: Favorite genre
      _WrappedSlide(
        gradient: const [Color(0xFF00B4D8), Color(0xFF0077B6)],
        child: _AnimatedStat(
          icon: Icons.category_rounded,
          label: 'Seu gênero favorito',
          value: data.favoriteGenre,
          subtitle: 'O que mais assistiu',
        ),
      ),

      // Slide 4: Favorite time
      _WrappedSlide(
        gradient: const [Color(0xFF2D00F7), Color(0xFF6A00F4)],
        child: _AnimatedStat(
          icon: Icons.nights_stay_rounded,
          label: 'Seu horário preferido',
          value: data.favoriteTimeOfDay,
          subtitle: '${data.totalDaysActive} dias ativos',
        ),
      ),

      // Slide 5: Top channel
      _WrappedSlide(
        gradient: const [Color(0xFFFF6D00), Color(0xFFFF9100)],
        child: _AnimatedStat(
          icon: Icons.live_tv_rounded,
          label: 'Top canal',
          value: data.topChannelName ?? 'Nenhum ainda',
          subtitle: 'Seu canal mais assistido',
        ),
      ),

      // Slide 6: Movies
      _WrappedSlide(
        gradient: const [Color(0xFFE63946), Color(0xFFF72585)],
        child: _AnimatedStat(
          icon: Icons.movie_rounded,
          label: 'Filmes assistidos',
          value: '${data.totalMoviesWatched}',
          subtitle: data.topMovieName != null
              ? 'Favorito: ${data.topMovieName}'
              : 'Continue explorando!',
        ),
      ),

      // Slide 7: Series
      _WrappedSlide(
        gradient: const [Color(0xFF06D6A0), Color(0xFF118AB2)],
        child: _AnimatedStat(
          icon: Icons.tv_rounded,
          label: 'Episódios de séries',
          value: '${data.totalSeriesEpisodes}',
          subtitle: data.topSeriesName != null
              ? 'Favorita: ${data.topSeriesName}'
              : 'Continue explorando!',
        ),
      ),

      // Slide 8: Summary
      _WrappedSlide(
        gradient: const [Color(0xFF6C63FF), Color(0xFF3F37C9)],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Seu ano em números',
              style: AppTypography.headline.copyWith(
                color: Colors.white,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 32),
            _SummaryRow(icon: Icons.schedule, label: 'Tempo total', value: '${data.totalHoursWatched}h ${data.totalMinutesRemainder}min'),
            _SummaryRow(icon: Icons.movie, label: 'Filmes', value: '${data.totalMoviesWatched}'),
            _SummaryRow(icon: Icons.tv, label: 'Episódios', value: '${data.totalSeriesEpisodes}'),
            _SummaryRow(icon: Icons.calendar_today, label: 'Dias ativos', value: '${data.totalDaysActive}'),
            _SummaryRow(icon: Icons.timer, label: 'Maior sessão', value: '${data.longestSessionMinutes} min'),
            _SummaryRow(icon: Icons.category, label: 'Gênero favorito', value: data.favoriteGenre),
            const SizedBox(height: 32),
            const Icon(Icons.blur_on_rounded, size: 40, color: Colors.white54),
            const SizedBox(height: 8),
            Text(
              'Nebula IPTV',
              style: AppTypography.label.copyWith(color: Colors.white54),
            ),
          ],
        ),
      ),
    ];
  }
}

/// A single wrapped slide with gradient background.
class _WrappedSlide extends StatelessWidget {
  final List<Color> gradient;
  final Widget child;

  const _WrappedSlide({required this.gradient, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      child: child,
    );
  }
}

/// Animated stat display with fade-in and scale.
class _AnimatedStat extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;

  const _AnimatedStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  State<_AnimatedStat> createState() => _AnimatedStatState();
}

class _AnimatedStatState extends State<_AnimatedStat>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 64, color: Colors.white70),
                const SizedBox(height: 24),
                Text(
                  widget.label,
                  style: AppTypography.body.copyWith(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.value,
                  style: AppTypography.display.copyWith(
                    color: Colors.white,
                    fontSize: 42,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.subtitle,
                  style: AppTypography.body.copyWith(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Summary row for the final slide.
class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white54),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTypography.body.copyWith(color: Colors.white70),
            ),
          ),
          Text(
            value,
            style: AppTypography.body.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
