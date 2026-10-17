import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/focusable_widget.dart';
import 'package:nebula_iptv/domain/services/subtitle_search_service.dart';
import 'package:nebula_iptv/domain/services/video_player_service.dart';
import 'package:nebula_iptv/features/player/providers/player_provider.dart';

/// Inline, D-pad-navigable track selector that lives inside the player overlay.
///
/// Replaces the old modal dialog so the user never leaves the video surface to
/// switch audio or subtitles. Layout on TV:
///
///   ┌────────────────────────────────────────────┐
///   │ Áudio & Legendas                            │ ← header; seleciona / fecha
///   ├────────────────────────────────────────────┤
///   │ [X] Legendas                    [ ] Áudio  │ ← seção atual (esq/dir muda)
///   ├────────────────────────────────────────────┤
///   │                                            │
///   │ ▼ Desativada                               │ ← item atual (cima/baixo move)
///   │    Nenhuma legenda exibida                 │
///   │ ──────────────────────────────────────     │
///   │    Legendas Embutidas                      │
///   │    Português (PT-BR)                       │
///   │    ...                                     │
///   │ ──────────────────────────────────────     │
///   │    Buscar legenda online (PT-BR)           │
///   └────────────────────────────────────────────┘
///
/// Selection model — cada seção lista todos os alvos disponíveis; selecionar
/// um aplica imediatamente (legenda via `selectSubtitleTrack`, áudio via
/// `selectAudioTrack`, legenda externa via `addExternalSubtitle`).
///
/// Back behaviour — pressionar Back na seção atual fecha o drawer e devolve o
/// foco à superfície do player. Selecionar uma faixa também fecha.
class TrackSelectorDrawer extends ConsumerStatefulWidget {
  final String contentTitle;
  final String? selectedAudioTrackId;
  final String? selectedSubtitleTrackId;
  final int? seasonNumber;
  final int? episodeNumber;
  final void Function(String) onSelectAudio;
  final void Function(String?) onSelectSubtitle;
  final void Function(String) onAddExternalSubtitle;

  const TrackSelectorDrawer({
    super.key,
    required this.contentTitle,
    this.selectedAudioTrackId,
    this.selectedSubtitleTrackId,
    this.seasonNumber,
    this.episodeNumber,
    required this.onSelectAudio,
    required this.onSelectSubtitle,
    required this.onAddExternalSubtitle,
  });

  @override
  ConsumerState<TrackSelectorDrawer> createState() =>
      _TrackSelectorDrawerState();
}

class _TrackSelectorDrawerState extends ConsumerState<TrackSelectorDrawer>
    with SingleTickerProviderStateMixin {
  int _tabIndex = 0;
  final _scroll = ScrollController();
  final _subtitleService = SubtitleSearchService();
  bool _searching = false;
  String? _searchError;
  final List<SubtitleResult> _onlineResults = [];
  late final TabController _tabController;

  VideoPlayerService get _player => ref.read(videoPlayerServiceProvider);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.92),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(),
            _tabBar(),
            Expanded(
              child: _tabIndex == 0 ? _subtitleList() : _audioList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.tune_rounded, color: AppColors.primary, size: 24),
          const SizedBox(width: 10),
          Text(
            'Áudio & Legendas',
            style: AppTypography.title.copyWith(fontSize: 18),
          ),
          const Spacer(),
          FocusableWidget(
            autofocus: true,
            onPressed: () => Navigator.of(context).pop(),
            builder: (_, focused) => Icon(
              Icons.close_rounded,
              color: focused ? Colors.white : Colors.white70,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          _TabChip(
            label: 'Legendas',
            icon: Icons.closed_caption_rounded,
            selected: _tabIndex == 0,
            onTap: () {
              setState(() => _tabIndex = 0);
              _tabController.animateTo(0);
            },
          ),
          const SizedBox(width: 4),
          _TabChip(
            label: 'Áudio',
            icon: Icons.audiotrack_rounded,
            selected: _tabIndex == 1,
            onTap: () {
              setState(() => _tabIndex = 1);
              _tabController.animateTo(1);
            },
          ),
        ],
      ),
    );
  }

  Widget _subtitleList() {
    final player = _player;

    return Stack(
      children: [
        StreamBuilder<List<VideoTrack>>(
          stream: player.subtitleTracks,
          initialData: const [],
          builder: (context, tracksSnapshot) {
            final tracks = tracksSnapshot.data ?? [];
            final items = <Widget>[];

            // Off / inactive
            final offSelected = widget.selectedSubtitleTrackId == null ||
                widget.selectedSubtitleTrackId == 'no';
            items.add(_ListItemWidget(
              title: 'Desativada',
              subtitle: 'Nenhuma legenda exibida',
              selected: offSelected,
              onTap: () {
                widget.onSelectSubtitle(null);
                Navigator.of(context).pop();
              },
              dividerAfter: true,
            ));

            if (tracks.isNotEmpty) {
              items.add(const _ListItemWidget(
                title: 'Legendas Embutidas',
                subtitle: null,
                selected: false,
                onTap: null,
                dividerAfter: true,
                dense: true,
              ));
              for (final t in tracks) {
                final title = t.title ?? t.language ?? 'Faixa #${t.id}';
                final lang =
                    t.language != null ? ' (${t.language!.toUpperCase()})' : '';
                items.add(_ListItemWidget(
                  title: '$title$lang',
                  subtitle: 'Embutida na transmissão',
                  selected: widget.selectedSubtitleTrackId == t.id,
                  onTap: () {
                    widget.onSelectSubtitle(t.id);
                    Navigator.of(context).pop();
                  },
                  dividerAfter: true,
                ));
              }
            }

            items.add(_ListItemWidget(
              title: 'Buscar Legenda Online (PT-BR)',
              subtitle: 'OpenSubtitles API',
              selected: false,
              onTap: _searchOnline,
              leadingIcon: Icons.cloud_download_rounded,
              dividerAfter: false,
            ));

            if (_searching) {
              items.add(const _ListItemWidget.loading());
            }
            if (_searchError != null) {
              items.add(_ListItemWidget(
                title: _searchError!,
                subtitle: null,
                selected: false,
                onTap: null,
                color: AppColors.textSecondary,
              ));
            }
            for (final sub in _onlineResults) {
              items.add(_ListItemWidget(
                title: sub.title,
                subtitle: '${sub.language} • Online',
                selected: false,
                onTap: () {
                  widget.onAddExternalSubtitle(sub.downloadUrl);
                  Navigator.of(context).pop();
                },
                dividerAfter: false,
              ));
            }

            return _ListWidget(items: items);
          },
        ),
      ],
    );
  }

  Widget _audioList() {
    final player = _player;

    return StreamBuilder<List<VideoTrack>>(
      stream: player.audioTracks,
      initialData: const [],
      builder: (context, tracksSnapshot) {
        final tracks = tracksSnapshot.data ?? [];
        final items = <Widget>[];

        if (tracks.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Áudio padrão da transmissão',
                style: TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        for (final t in tracks) {
          final title = t.title ?? t.language ?? 'Áudio #${t.id}';
          final lang =
              t.language != null ? ' (${t.language!.toUpperCase()})' : '';
          final lower = (title + (t.language ?? '')).toLowerCase();
          final isPt = lower.contains('port') ||
              lower.contains('dub') ||
              (t.language ?? '').toLowerCase().startsWith('pt');
          final subtitle =
              isPt ? 'Dublado em Português' : 'Áudio da transmissão';
          final idx = tracks.indexOf(t);
          items.add(_ListItemWidget(
            title: '$title$lang',
            subtitle: subtitle,
            selected: widget.selectedAudioTrackId == t.id ||
                (widget.selectedAudioTrackId == null && idx == 0),
            onTap: () {
              widget.onSelectAudio(t.id);
              Navigator.of(context).pop();
            },
            dividerAfter: true,
          ));
        }

        return _ListWidget(items: items);
      },
    );
  }

  Future<void> _searchOnline() async {
    setState(() {
      _searching = true;
      _searchError = null;
      _onlineResults.clear();
    });

    try {
      final results = await _subtitleService.searchSubtitles(
        query: widget.contentTitle,
        language: 'pt-br',
        seasonNumber: widget.seasonNumber,
        episodeNumber: widget.episodeNumber,
      );
      if (!mounted) return;
      setState(() {
        _searching = false;
        if (results.isEmpty) {
          _searchError = 'Nenhuma legenda encontrada online para este título.';
        } else {
          _onlineResults.addAll(results);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _searchError = 'Erro ao buscar legendas. Tente novamente.';
      });
    }
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FocusableWidget(
        onPressed: onTap,
        builder: (_, focused) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: focused
                    ? AppColors.primary
                    : selected
                        ? AppColors.primary
                        : Colors.white60,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.body.copyWith(
                  color:
                      focused || selected ? AppColors.primary : Colors.white60,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListItemWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? leadingIcon;
  final bool dividerAfter;
  final bool dense;
  final Color? color;
  final bool loading;

  const _ListItemWidget({
    required this.title,
    this.subtitle,
    this.selected = false,
    this.onTap,
    this.leadingIcon,
    this.dividerAfter = false,
    this.dense = false,
    this.color,
  }) : loading = false;

  const _ListItemWidget.loading()
      : title = '', subtitle = null, selected = false, onTap = null,
        leadingIcon = null, dividerAfter = false, dense = false, color = null, loading = true;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final bg = selected
        ? AppColors.primary.withValues(alpha: 0.15)
        : color ?? Colors.transparent;
    final borderColor = selected ? AppColors.primary : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: FocusableWidget(
        onPressed: onTap,
        builder: (_, focused) => Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Row(
              children: [
                if (leadingIcon != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(
                      leadingIcon,
                      size: 18,
                      color:
                          focused ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ] else
                  const SizedBox(width: 32),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.body.copyWith(
                            color: selected ? AppColors.primary : Colors.white,
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                ),
                if (selected)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListWidget extends StatelessWidget {
  final List<Widget> items;

  const _ListWidget({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map((item) => Column(
                  children: [
                    item,
                    const Divider(color: AppColors.divider, height: 1),
                  ],
                ))
            .toList(),
      ),
    );
  }
}
