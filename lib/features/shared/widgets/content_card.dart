import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/nebula_cached_image.dart';
import 'package:nebula_iptv/core/widgets/nebula_focus_ring.dart';

/// A Netflix-style content card with poster image (2:3 ratio).
///
/// Features:
/// - Hover/focus scale animation (1.05x)
/// - Title overlay on hover
/// - Optional progress bar at bottom
/// - Optional badge (e.g., "Novo")
/// - Fallback icon when no poster available
class ContentCard extends StatefulWidget {
  final String title;
  final String? imageUrl;
  final String? subtitle;
  final double? progress;
  final String? badge;
  final IconData fallbackIcon;
  final VoidCallback? onTap;
  final double width;
  final void Function(Offset position)? onSecondaryTap;

  const ContentCard({
    super.key,
    required this.title,
    this.imageUrl,
    this.subtitle,
    this.progress,
    this.badge,
    this.fallbackIcon = Icons.movie_rounded,
    this.onTap,
    this.width = 140,
    this.onSecondaryTap,
  });

  @override
  State<ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<ContentCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isFocused = false;
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    setState(() => _isHovered = hovering);
    if (hovering) {
      _scaleController.forward();
    } else {
      _scaleController.reverse();
    }
  }

  void _onFocusChange(bool focused) {
    setState(() => _isFocused = focused);
    if (focused) {
      _scaleController.forward();
    } else {
      _scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final showOverlay = _isHovered || _isFocused;

    return Focus(
      onFocusChange: _onFocusChange,
      child: MouseRegion(
        onEnter: (_) => _onHover(true),
        onExit: (_) => _onHover(false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          onSecondaryTapUp: widget.onSecondaryTap != null
              ? (details) {
                  widget.onSecondaryTap!(details.globalPosition);
                }
              : null,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              );
            },
            child: NebulaFocusRing(
              focused: _isFocused,
              radius: 8,
              child: SizedBox(
                width: widget.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Poster area (2:3 ratio)
                    AspectRatio(
                      aspectRatio: 2 / 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          // Glow da marca no lugar de sombra: sombra não lê
                          // bem em fundo void950 (DESIGN.md §4).
                          boxShadow: showOverlay
                              ? [
                                  BoxShadow(
                                    color: AppColors.nebulaViolet
                                        .withValues(alpha: 0.20),
                                    blurRadius: 24,
                                  ),
                                ]
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Image or fallback
                              _buildImage(),

                              // Title overlay on hover
                              if (showOverlay)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black87,
                                        ],
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          widget.title,
                                          style: AppTypography.caption.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (widget.subtitle != null)
                                          Text(
                                            widget.subtitle!,
                                            style:
                                                AppTypography.caption.copyWith(
                                              color: Colors.white70,
                                              fontSize: 10,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),

                              // Badge
                              if (widget.badge != null)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      widget.badge!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                              // Progress bar at bottom
                              if (widget.progress != null &&
                                  widget.progress! > 0)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: LinearProgressIndicator(
                                    value: widget.progress!.clamp(0.0, 1.0),
                                    backgroundColor:
                                        Colors.black.withValues(alpha: 0.5),
                                    color: widget.progress! >= 0.95
                                        ? AppColors.success
                                        : AppColors.primary,
                                    minHeight: 3,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Title below card (always visible)
                    const SizedBox(height: 6),
                    Text(
                      widget.title,
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.subtitle != null)
                      Text(
                        widget.subtitle!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return NebulaCachedImage(
      imageUrl: widget.imageUrl,
      fit: BoxFit.cover,
      cacheWidth: 300,
      cacheHeight: 450,
      placeholder: _buildFallback(),
    );
  }

  Widget _buildFallback() {
    return Container(
      color: AppColors.surfaceElevated,
      child: Center(
        child: Icon(
          widget.fallbackIcon,
          color: AppColors.textSecondary.withValues(alpha: 0.5),
          size: 36,
        ),
      ),
    );
  }
}
