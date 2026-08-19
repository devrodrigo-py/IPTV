import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/widgets/empty_view.dart';
import 'package:nebula_iptv/l10n/app_localizations.dart';

/// Playlists/Sources screen placeholder.
///
/// Full implementation in Phase 4.
class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EmptyView(
      icon: Icons.playlist_play_rounded,
      message: l10n.playlists,
    );
  }
}
