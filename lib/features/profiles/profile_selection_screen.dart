import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';
import 'package:nebula_iptv/features/profiles/profile_edit_dialog.dart';
import 'package:nebula_iptv/features/profiles/providers/profile_provider.dart';
import 'package:nebula_iptv/core/widgets/nebula_brand.dart';

/// Netflix-style profile selection screen shown at app startup.
class ProfileSelectionScreen extends ConsumerStatefulWidget {
  final VoidCallback onProfileSelected;

  const ProfileSelectionScreen({
    super.key,
    required this.onProfileSelected,
  });

  @override
  ConsumerState<ProfileSelectionScreen> createState() =>
      _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState
    extends ConsumerState<ProfileSelectionScreen> {
  bool _isManaging = false;

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(profilesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            const NebulaBrand(height: 72),
            const SizedBox(height: 16),
            Text(
              'Quem está assistindo?',
              style: AppTypography.headline.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 48),

            // Profile grid
            profilesAsync.when(
              data: (profiles) => _buildProfileGrid(profiles),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Erro ao carregar perfis'),
            ),

            const SizedBox(height: 32),

            // Manage profiles button
            TextButton.icon(
              onPressed: () {
                setState(() => _isManaging = !_isManaging);
              },
              icon: Icon(
                _isManaging ? Icons.done : Icons.edit,
                size: 18,
              ),
              label: Text(
                _isManaging ? 'Concluído' : 'Gerenciar perfis',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileGrid(List<Map<String, dynamic>> profiles) {
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      alignment: WrapAlignment.center,
      children: [
        ...profiles.map((p) => _buildProfileAvatar(p)),
        if (profiles.length < 5) _buildAddProfile(),
      ],
    );
  }

  Widget _buildProfileAvatar(Map<String, dynamic> profile) {
    final name = profile['name'] as String;
    final iconName = profile['avatar_icon'] as String;
    final colorHex = profile['avatar_color'] as String;
    final id = profile['id'] as int;
    final color = _parseColor(colorHex);
    final icon = _parseIcon(iconName);

    return GestureDetector(
      onTap: () {
        if (_isManaging) {
          _editProfile(profile);
        } else {
          ref.read(activeProfileProvider.notifier).state = id;
          widget.onProfileSelected();
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color, width: 2.5),
                  ),
                  child: Icon(icon, size: 48, color: color),
                ),
                if (_isManaging && profile['is_default'] != 1)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: () => _deleteProfile(id),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                if (_isManaging)
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: color),
                      ),
                      child: Icon(Icons.edit, size: 12, color: color),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: AppTypography.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddProfile() {
    return GestureDetector(
      onTap: _createProfile,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.divider,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 48,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adicionar',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createProfile() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const ProfileEditDialog(),
    );
    if (result != null) {
      final db = ref.read(databaseProvider);
      await db.profileDao.insertProfile(
        name: result['name']!,
        avatarIcon: result['icon']!,
        avatarColor: result['color']!,
      );
      ref.invalidate(profilesProvider);
    }
  }

  Future<void> _editProfile(Map<String, dynamic> profile) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => ProfileEditDialog(
        initialName: profile['name'] as String,
        initialIcon: profile['avatar_icon'] as String,
        initialColor: profile['avatar_color'] as String,
      ),
    );
    if (result != null) {
      final db = ref.read(databaseProvider);
      await db.profileDao.updateProfile(
        id: profile['id'] as int,
        name: result['name']!,
        avatarIcon: result['icon']!,
        avatarColor: result['color']!,
      );
      ref.invalidate(profilesProvider);
    }
  }

  Future<void> _deleteProfile(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir perfil?'),
        content: const Text(
          'Todo o histórico e favoritos deste perfil serão perdidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final db = ref.read(databaseProvider);
      await db.profileDao.deleteProfile(id);
      ref.invalidate(profilesProvider);
    }
  }

  Color _parseColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  IconData _parseIcon(String name) {
    return switch (name) {
      'person' => Icons.person_rounded,
      'child' => Icons.child_care_rounded,
      'star' => Icons.star_rounded,
      'pets' => Icons.pets_rounded,
      'sports' => Icons.sports_esports_rounded,
      'music' => Icons.music_note_rounded,
      'movie' => Icons.movie_rounded,
      'school' => Icons.school_rounded,
      _ => Icons.person_rounded,
    };
  }
}
