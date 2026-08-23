import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';
import 'package:nebula_iptv/features/profiles/providers/profile_provider.dart';
import 'package:nebula_iptv/features/shortcuts/providers/shortcut_provider.dart';

/// Shows a context menu for adding/removing shortcuts.
///
/// Call this from onSecondaryTap handlers in any screen.
Future<void> showShortcutContextMenu(
  BuildContext context,
  WidgetRef ref, {
  required Offset position,
  required int channelId,
  required String channelName,
}) async {
  final db = ref.read(databaseProvider);
  final profileId = ref.read(activeProfileProvider);
  final isSaved = await db.shortcutDao.isShortcut(profileId, channelId);

  if (!context.mounted) return;

  final result = await showMenu<String>(
    context: context,
    position: RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      position.dx + 1,
      position.dy + 1,
    ),
    color: AppColors.surfaceElevated,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    items: [
      PopupMenuItem<String>(
        value: isSaved ? 'remove' : 'add',
        child: Row(
          children: [
            Icon(
              isSaved ? Icons.bookmark_remove_rounded : Icons.bookmark_add_rounded,
              size: 18,
              color: isSaved ? AppColors.error : AppColors.primary,
            ),
            const SizedBox(width: 10),
            Text(
              isSaved ? 'Remover dos atalhos' : 'Adicionar aos atalhos',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
          ],
        ),
      ),
    ],
  );

  if (result == null || !context.mounted) return;

  if (result == 'add') {
    await db.shortcutDao.addShortcut(profileId, channelId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$channelName adicionado aos atalhos'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  } else {
    await db.shortcutDao.removeShortcut(profileId, channelId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$channelName removido dos atalhos'),
          backgroundColor: AppColors.surface,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Refresh shortcuts provider
  ref.invalidate(shortcutsProvider);
}
