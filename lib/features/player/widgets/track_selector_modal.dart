import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/domain/services/subtitle_search_service.dart';
import 'package:nebula_iptv/domain/services/video_player_service.dart';
import 'package:nebula_iptv/features/player/providers/player_provider.dart';

/// Modal dialog for choosing Audio track, Subtitles, and injecting external .srt/.vtt.
class TrackSelectorModal extends ConsumerStatefulWidget {
  final String contentTitle;
  final String? selectedAudioTrackId;
  final String? selectedSubtitleTrackId;
  final int? seasonNumber;
  final int? episodeNumber;
  final ValueChanged<String> onSelectAudio;
  final ValueChanged<String?> onSelectSubtitle;
  final ValueChanged<String> onAddExternalSubtitle;

  const TrackSelectorModal({
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
  ConsumerState<TrackSelectorModal> createState() => _TrackSelectorModalState();
}

class _TrackSelectorModalState extends ConsumerState<TrackSelectorModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _urlController = TextEditingController();
  final _subtitleService = SubtitleSearchService();

  bool _isSearchingOnline = false;
  List<SubtitleResult> _onlineResults = [];
  String? _onlineSearchError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _performOnlineSearch() async {
    setState(() {
      _isSearchingOnline = true;
      _onlineSearchError = null;
    });

    try {
      final results = await _subtitleService.searchSubtitles(
        query: widget.contentTitle,
        language: 'pt-br',
        seasonNumber: widget.seasonNumber,
        episodeNumber: widget.episodeNumber,
      );
      if (mounted) {
        setState(() {
          _onlineResults = results;
          _isSearchingOnline = false;
          if (results.isEmpty) {
            _onlineSearchError =
                'Nenhuma legenda encontrada online para este título.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearchingOnline = false;
          _onlineSearchError = 'Erro ao buscar legendas. Tente novamente.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerService = ref.read(videoPlayerServiceProvider);

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        height: 480,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Title & Close Button
            Row(
              children: [
                const Icon(Icons.tune_rounded,
                    color: AppColors.primary, size: 24),
                const SizedBox(width: 10),
                Text('Áudio & Legendas',
                    style: AppTypography.title.copyWith(fontSize: 18)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Tabs: Áudio & Legendas
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: const [
                  Tab(
                      icon: Icon(Icons.closed_caption_rounded, size: 20),
                      text: 'Legendas'),
                  Tab(
                      icon: Icon(Icons.audiotrack_rounded, size: 20),
                      text: 'Áudio'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Subtitles
                  _buildSubtitlesTab(playerService),

                  // Tab 2: Audio Tracks
                  _buildAudioTab(playerService),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitlesTab(VideoPlayerService playerService) {
    return StreamBuilder<List<VideoTrack>>(
      stream: playerService.subtitleTracks,
      initialData: const [],
      builder: (context, snapshot) {
        final tracks = snapshot.data ?? [];
        final isOffSelected = widget.selectedSubtitleTrackId == null ||
            widget.selectedSubtitleTrackId == 'no';

        return ListView(
          children: [
            // Off / Disabled option
            _buildTrackTile(
              title: 'Desativada',
              subtitle: 'Nenhuma legenda exibida',
              isSelected: isOffSelected,
              onTap: () {
                widget.onSelectSubtitle(null);
                Navigator.of(context).pop();
              },
            ),
            const Divider(color: AppColors.divider, height: 1),

            // Embedded Subtitles list
            if (tracks.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Text(
                  'Legendas Embutidas',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
              ...tracks.map((track) {
                final isSelected = widget.selectedSubtitleTrackId == track.id;
                final title =
                    track.title ?? track.language ?? 'Faixa #${track.id}';
                final lang = track.language != null
                    ? ' (${track.language!.toUpperCase()})'
                    : '';

                return _buildTrackTile(
                  title: '$title$lang',
                  subtitle: 'Embutida na transmissão',
                  isSelected: isSelected,
                  onTap: () {
                    widget.onSelectSubtitle(track.id);
                    Navigator.of(context).pop();
                  },
                );
              }),
              const Divider(color: AppColors.divider, height: 1),
            ],

            // Action: Search Online Subtitles
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                tileColor: AppColors.surfaceElevated,
                leading: const Icon(Icons.cloud_download_rounded,
                    color: AppColors.primary),
                title: const Text('Buscar Legenda Online (PT-BR)',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                subtitle: const Text('OpenSubtitles API',
                    style: TextStyle(color: Colors.white54, fontSize: 11)),
                onTap: _performOnlineSearch,
              ),
            ),

            if (_isSearchingOnline)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),

            if (_onlineSearchError != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(_onlineSearchError!,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ),

            // Online Search Results
            if (_onlineResults.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(8, 12, 8, 4),
                child: Text('Resultados Online:',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
              ..._onlineResults.map((sub) {
                return _buildTrackTile(
                  title: sub.title,
                  subtitle: '${sub.language} • Online',
                  isSelected: false,
                  onTap: () {
                    widget.onAddExternalSubtitle(sub.downloadUrl);
                    Navigator.of(context).pop();
                  },
                );
              }),
            ],

            // Action: Add by URL (.srt / .vtt)
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Colar link .srt ou .vtt...',
                      hintStyle:
                          const TextStyle(color: Colors.white38, fontSize: 12),
                      filled: true,
                      fillColor: AppColors.surfaceElevated,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary),
                  onPressed: () {
                    if (_urlController.text.isNotEmpty) {
                      widget.onAddExternalSubtitle(_urlController.text.trim());
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Adicionar',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildAudioTab(VideoPlayerService playerService) {
    return StreamBuilder<List<VideoTrack>>(
      stream: playerService.audioTracks,
      initialData: const [],
      builder: (context, snapshot) {
        final tracks = snapshot.data ?? [];
        if (tracks.isEmpty) {
          return const Center(
            child: Text(
              'Áudio padrão da transmissão',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          );
        }

        return ListView.builder(
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final track = tracks[index];
            final isSelected = widget.selectedAudioTrackId == track.id ||
                (widget.selectedAudioTrackId == null && index == 0);
            final title = track.title ?? track.language ?? 'Áudio #${track.id}';
            final lang = track.language != null
                ? ' (${track.language!.toUpperCase()})'
                : '';

            final isPortuguese = title.toLowerCase().contains('port') ||
                title.toLowerCase().contains('dub') ||
                (track.language ?? '').toLowerCase().startsWith('pt');

            return _buildTrackTile(
              title: '$title$lang',
              subtitle: isPortuguese
                  ? 'Dublado em Português'
                  : 'Áudio da transmissão',
              isSelected: isSelected,
              onTap: () {
                widget.onSelectAudio(track.id);
                Navigator.of(context).pop();
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTrackTile({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      // ListTile pinta no Material mais próximo; sem isto o fundo do
      // Container esconde o destaque de seleção (asserção do framework).
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          dense: true,
          title: Text(
            title,
            style: TextStyle(
              color: isSelected ? AppColors.primary : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          trailing: isSelected
              ? const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 20)
              : null,
          onTap: onTap,
        ),
      ),
    );
  }
}
