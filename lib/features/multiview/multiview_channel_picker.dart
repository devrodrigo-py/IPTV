import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';
import 'package:nebula_iptv/features/multiview/multiview_screen.dart';

/// Dialog for selecting channels to watch in multiview.
class MultiviewChannelPicker extends ConsumerStatefulWidget {
  const MultiviewChannelPicker({super.key});

  @override
  ConsumerState<MultiviewChannelPicker> createState() =>
      _MultiviewChannelPickerState();
}

class _MultiviewChannelPickerState
    extends ConsumerState<MultiviewChannelPicker> {
  final Set<int> _selectedIds = {};
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(channelsScreenProvider);
    final channels = state.filteredChannels
        .where((c) =>
            _searchQuery.isEmpty ||
            c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Dialog(
      backgroundColor: AppColors.surface,
      child: SizedBox(
        width: 500,
        height: 600,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.grid_view_rounded, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text('Multiview', style: AppTypography.title),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Instructions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Selecione 2 a 4 canais para assistir simultaneamente.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Buscar canal...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            const SizedBox(height: 8),

            // Selection count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '${_selectedIds.length}/4 selecionados',
                    style: AppTypography.caption.copyWith(
                      color: _selectedIds.length >= 2
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_selectedIds.isNotEmpty) ...[
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(() => _selectedIds.clear()),
                      child: const Text('Limpar'),
                    ),
                  ],
                ],
              ),
            ),

            // Channel list
            Expanded(
              child: ListView.builder(
                itemCount: channels.length,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemBuilder: (context, index) {
                  final channel = channels[index];
                  final isSelected = _selectedIds.contains(channel.id);
                  final canSelect =
                      _selectedIds.length < 4 || isSelected;

                  return ListTile(
                    leading: _buildLeading(channel, isSelected),
                    title: Text(
                      channel.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: channel.groupName != null
                        ? Text(
                            channel.groupName!,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          )
                        : null,
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: canSelect
                          ? (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedIds.add(channel.id);
                                } else {
                                  _selectedIds.remove(channel.id);
                                }
                              });
                            }
                          : null,
                      activeColor: AppColors.primary,
                    ),
                    onTap: canSelect
                        ? () {
                            setState(() {
                              if (isSelected) {
                                _selectedIds.remove(channel.id);
                              } else {
                                _selectedIds.add(channel.id);
                              }
                            });
                          }
                        : null,
                  );
                },
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _selectedIds.length >= 2
                        ? () => _startMultiview(channels)
                        : null,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Iniciar Multiview'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeading(Channel channel, bool isSelected) {
    if (channel.logoUrl != null && channel.logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          channel.logoUrl!,
          width: 40,
          height: 40,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildFallbackIcon(isSelected),
        ),
      );
    }
    return _buildFallbackIcon(isSelected);
  }

  Widget _buildFallbackIcon(bool isSelected) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.2)
            : AppColors.background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        Icons.live_tv_rounded,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        size: 20,
      ),
    );
  }

  void _startMultiview(List<Channel> channels) {
    final selected = channels
        .where((c) => _selectedIds.contains(c.id))
        .map((c) => {
              'id': c.id,
              'name': c.name,
              'stream_url': c.streamUrl,
            })
        .toList();

    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiviewScreen(channels: selected),
      ),
    );
  }
}
