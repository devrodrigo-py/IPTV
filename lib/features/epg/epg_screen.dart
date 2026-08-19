import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nebula_iptv/core/theme/app_colors.dart';

import 'package:nebula_iptv/core/theme/app_typography.dart';

import 'package:nebula_iptv/core/widgets/empty_view.dart';

import 'package:nebula_iptv/core/widgets/loading_view.dart';

import 'package:nebula_iptv/data/database/app_database.dart';

import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';

import 'package:nebula_iptv/l10n/app_localizations.dart';

/// Provider for EPG programs of a selected channel.

final epgProgramsProvider =
    FutureProvider.family<List<EpgProgram>, int>((ref, channelId) async {
  final db = ref.read(databaseProvider);

  return db.epgDao.getProgramsForChannel(channelId);
});

/// EPG screen showing program schedule.

///

/// Displays channels with their current and upcoming programs.

/// Times are displayed in the device's local timezone (spec §4.4).

class EpgScreen extends ConsumerWidget {
  const EpgScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final channelsState = ref.watch(channelsScreenProvider);

    if (channelsState.isLoading) return const LoadingView();

    if (channelsState.allChannels.isEmpty) {
      return EmptyView(
        icon: Icons.schedule_rounded,
        message: l10n.epg,
      );
    }

    return ListView.builder(
      itemCount: channelsState.allChannels.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final channel = channelsState.allChannels[index];

        return _EpgChannelRow(channel: channel);
      },
    );
  }
}

/// Shows a channel with its current program.

class _EpgChannelRow extends ConsumerWidget {
  final Channel channel;

  const _EpgChannelRow({required this.channel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programsAsync = ref.watch(epgProgramsProvider(channel.id));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Channel name

          SizedBox(
            width: 140,
            child: Text(
              channel.name,
              style: AppTypography.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: 12),

          // Current program

          Expanded(
            child: programsAsync.when(
              loading: () => const Text(
                '...',
                style: AppTypography.caption,
              ),
              error: (_, __) => const Text(
                'Sem programação',
                style: AppTypography.caption,
              ),
              data: (programs) {
                if (programs.isEmpty) {
                  return const Text(
                    'Sem programação',
                    style: AppTypography.caption,
                  );
                }

                final now = DateTime.now().toUtc();

                final current = programs.where(
                  (p) =>
                      p.startTimeUtc.isBefore(now) && p.endTimeUtc.isAfter(now),
                );

                if (current.isEmpty) {
                  final next = programs.first;

                  return _ProgramInfo(
                    label: 'Próximo',
                    title: next.title,
                    time: next.startTimeUtc.toLocal(),
                  );
                }

                return _ProgramInfo(
                  label: 'Agora',
                  title: current.first.title,
                  time: current.first.endTimeUtc.toLocal(),
                  isLive: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays program info (title + time).

class _ProgramInfo extends StatelessWidget {
  final String label;

  final String title;

  final DateTime time;

  final bool isLive;

  const _ProgramInfo({
    required this.label,
    required this.title,
    required this.time,
    this.isLive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (isLive)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontSize: 9,
                  ),
                ),
              )
            else
              Text(
                '$label: ',
                style: AppTypography.caption,
              ),
            Expanded(
              child: Text(
                title,
                style: AppTypography.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${time.hour.toString().padLeft(2, '0')}:'
          '${time.minute.toString().padLeft(2, '0')}',
          style: AppTypography.caption,
        ),
      ],
    );
  }
}
