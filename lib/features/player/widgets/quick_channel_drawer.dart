import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/cached_logo.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';
import 'package:nebula_iptv/features/epg/providers/epg_provider.dart';

/// Semi-transparent quick channel drawer that slides in over the player.
///
/// Allows channel switching, category filtering, and viewing current EPG
/// without leaving the live video stream.
class QuickChannelDrawer extends ConsumerStatefulWidget {
  final int? currentChannelId;
  final ValueChanged<Channel> onChannelSelected;
  final VoidCallback onClose;

  const QuickChannelDrawer({
    super.key,
    required this.currentChannelId,
    required this.onChannelSelected,
    required this.onClose,
  });

  @override
  ConsumerState<QuickChannelDrawer> createState() => _QuickChannelDrawerState();
}

class _QuickChannelDrawerState extends ConsumerState<QuickChannelDrawer> {
  String? _selectedCategory;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channelsState = ref.watch(channelsScreenProvider);
    final allChannels = channelsState.allChannels;
    final categories = channelsState.groups;

    var filtered = allChannels;
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filtered = filtered
          .where((c) => (c.groupName ?? 'Sem Categoria') == _selectedCategory)
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((c) => c.name.toLowerCase().contains(q)).toList();
    }

    return FocusScope(
      child: Container(
        width: 360,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.90),
          border: const Border(
            right: BorderSide(color: AppColors.divider, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 20,
              offset: const Offset(4, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header: Title & Close Button
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
                child: Row(
                  children: [
                    const Icon(Icons.live_tv_rounded, color: AppColors.primary, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Guia Rápido',
                      style: AppTypography.title.copyWith(fontSize: 18),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: widget.onClose,
                      tooltip: 'Fechar',
                    ),
                  ],
                ),
              ),
            ),

            // Search input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Buscar canal...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16, color: Colors.white54),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                ),
              ),
            ),

            // Category Chips (horizontal scroll)
            if (categories.isNotEmpty)
              SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length + 1,
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final catName = isAll ? 'Todos' : categories[index - 1];
                    final isSelected = isAll
                        ? _selectedCategory == null
                        : _selectedCategory == catName;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          catName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceElevated,
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = isAll ? null : catName;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 8),
            const Divider(color: AppColors.divider, height: 1),

            // Channel List with EPG
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum canal encontrado',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final channel = filtered[index];
                        final isPlaying = widget.currentChannelId == channel.id;

                        return _ChannelDrawerTile(
                          channel: channel,
                          isPlaying: isPlaying,
                          onTap: () => widget.onChannelSelected(channel),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChannelDrawerTile extends ConsumerStatefulWidget {
  final Channel channel;
  final bool isPlaying;
  final VoidCallback onTap;

  const _ChannelDrawerTile({
    required this.channel,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  ConsumerState<_ChannelDrawerTile> createState() => _ChannelDrawerTileState();
}

class _ChannelDrawerTileState extends ConsumerState<_ChannelDrawerTile> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    // EPG current program
    final epgAsync = ref.watch(currentProgramProvider(widget.channel.id));
    final currentProgram = epgAsync.valueOrNull;

    return Focus(
      onFocusChange: (f) => setState(() => _isFocused = f),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.select)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isPlaying
                ? AppColors.primary.withValues(alpha: 0.25)
                : _isFocused
                    ? AppColors.surfaceElevated
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isFocused
                  ? AppColors.primary
                  : widget.isPlaying
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : Colors.transparent,
              width: _isFocused ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Logo
              CachedLogo(
                imageUrl: widget.channel.logoUrl,
                size: 38,
              ),
              const SizedBox(width: 10),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.channel.name,
                      style: TextStyle(
                        color: widget.isPlaying ? AppColors.primary : Colors.white,
                        fontWeight: widget.isPlaying ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentProgram?.title ?? widget.channel.groupName ?? 'Ao Vivo',
                      style: TextStyle(
                        color: widget.isPlaying
                            ? Colors.white70
                            : AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Playing indicator
              if (widget.isPlaying)
                const Icon(
                  Icons.volume_up_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
