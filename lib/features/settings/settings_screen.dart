import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/focusable_widget.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';
import 'package:nebula_iptv/features/profiles/profile_edit_dialog.dart';
import 'package:nebula_iptv/features/profiles/providers/profile_provider.dart';
import 'package:nebula_iptv/l10n/app_localizations.dart';

/// Settings screen.
///
/// Provides access to application configuration including profiles.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profilesAsync = ref.watch(profilesProvider);
    final activeId = ref.watch(activeProfileProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          Text(
            l10n.settings,
            style: AppTypography.title,
          ),
          const SizedBox(height: 24),

          // Profiles section
          _SettingsSection(
            title: 'Perfis',
            children: [
              ...profilesAsync.when(
                data: (profiles) => profiles.map<Widget>((p) {
                  final id = p['id'] as int;
                  final isActive = id == activeId;
                  final name = p['name'] as String? ?? 'Perfil';
                  return _SettingsTile(
                    icon: isActive
                        ? Icons.person_rounded
                        : Icons.person_outline_rounded,
                    title: name,
                    subtitle: isActive ? '● Ativo' : 'Toque para ativar',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          color: AppColors.textSecondary,
                          onPressed: () async {
                            final result = await showDialog<Map<String, String>>(
                              context: context,
                              builder: (_) => ProfileEditDialog(
                                initialName: name,
                                initialIcon: p['avatar_icon'] as String? ?? 'person',
                                initialColor: p['avatar_color'] as String? ?? '#7B2FF7',
                              ),
                            );
                            if (result != null) {
                              final db = ref.read(databaseProvider);
                              await db.profileDao.updateProfile(
                                id: id,
                                name: result['name']!,
                                avatarIcon: result['icon']!,
                                avatarColor: result['color']!,
                              );
                            }
                            ref.invalidate(profilesProvider);
                          },
                        ),
                        if (!isActive && (p['is_default'] as int? ?? 0) == 0)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            color: AppColors.error,
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  backgroundColor: AppColors.surface,
                                  title: const Text('Excluir perfil?'),
                                  content: Text('Isso vai excluir o perfil "$name" e seus atalhos.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
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
                            },
                          ),
                      ],
                    ),
                    onTap: () {
                      ref.read(activeProfileProvider.notifier).state = id;
                    },
                  );
                }).toList(),
                loading: () => [const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                )],
                error: (_, __) => [const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Erro ao carregar perfis'),
                )],
              ),
              _SettingsTile(
                icon: Icons.add_rounded,
                title: 'Adicionar perfil',
                subtitle: 'Criar um novo perfil',
                onTap: () async {
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
                  }
                  ref.invalidate(profilesProvider);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // General section
          _SettingsSection(
            title: l10n.settingsGeneral,
            children: [
              _SettingsTile(
                icon: Icons.palette_rounded,
                title: l10n.settingsTheme,
                subtitle: l10n.settingsThemeDark,
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.language_rounded,
                title: l10n.settingsLanguage,
                subtitle: l10n.settingsLanguagePtBr,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: l10n.settingsAbout,
            children: [
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: l10n.appTitle,
                subtitle: 'v0.1.0',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.label,
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return FocusableWidget(
      onPressed: onTap ?? () {},
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      builder: (context, isFocused) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.body),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTypography.caption),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        );
      },
    );
  }
}
