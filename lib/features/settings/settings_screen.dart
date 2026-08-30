import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/focusable_widget.dart';
import 'package:nebula_iptv/data/database/tables/playlists_table.dart';
import 'package:nebula_iptv/domain/providers/health_check_providers.dart';
import 'package:nebula_iptv/domain/services/subtitle_search_service.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';
import 'package:nebula_iptv/features/parental_control/parental_control_service.dart';
import 'package:nebula_iptv/features/playlists/providers/playlist_management_provider.dart';
import 'package:nebula_iptv/features/profiles/profile_edit_dialog.dart';
import 'package:nebula_iptv/features/profiles/providers/profile_provider.dart';
import 'package:nebula_iptv/features/search/providers/search_provider.dart'
    show batchEnrichmentProvider;
import 'package:nebula_iptv/l10n/app_localizations.dart';

/// Settings screen.
///
/// Provides access to application configuration including profiles,
/// accounts/subscriptions, parental control, and audio/subtitle preferences.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profilesAsync = ref.watch(profilesProvider);
    final activeId = ref.watch(activeProfileProvider);
    final playlistState = ref.watch(playlistManagementProvider);
    final parentalState = ref.watch(parentalControlProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          Text(
            l10n.settings,
            style: AppTypography.title,
          ),
          const SizedBox(height: 24),

          // 1. Profiles section
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
                            final result =
                                await showDialog<Map<String, String>>(
                              context: context,
                              builder: (_) => ProfileEditDialog(
                                initialName: name,
                                initialIcon:
                                    p['avatar_icon'] as String? ?? 'person',
                                initialColor:
                                    p['avatar_color'] as String? ?? '#7B2FF7',
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
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18),
                            color: AppColors.error,
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  backgroundColor: AppColors.surface,
                                  title: const Text('Excluir perfil?'),
                                  content: Text(
                                      'Isso vai excluir o perfil "$name" e seus atalhos.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: TextButton.styleFrom(
                                          foregroundColor: AppColors.error),
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
                loading: () => [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ],
                error: (_, __) => [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Erro ao carregar perfis'),
                  ),
                ],
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

          // 2. Subscriptions / Accounts Info
          _SettingsSection(
            title: 'Assinaturas & Servidores IPTV',
            children: [
              if (playlistState.playlists.isEmpty)
                const _SettingsTile(
                  icon: Icons.cloud_off_rounded,
                  title: 'Nenhuma fonte cadastrada',
                  subtitle: 'Adicione uma lista M3U ou Xtream na aba Fontes',
                )
              else
                ...playlistState.playlists.map((playlist) {
                  final isXtream = playlist.type == PlaylistType.xtream;
                  final user = playlist.username ?? 'Anônimo';
                  final lastSync = playlist.lastSyncAt != null
                      ? '${playlist.lastSyncAt!.day.toString().padLeft(2, '0')}/${playlist.lastSyncAt!.month.toString().padLeft(2, '0')}/${playlist.lastSyncAt!.year}'
                      : 'Nunca sincronizado';

                  return _SettingsTile(
                    icon: isXtream
                        ? Icons.dns_rounded
                        : Icons.playlist_play_rounded,
                    title: playlist.name,
                    subtitle: isXtream
                        ? 'Xtream Codes • Usuário: $user • Atualizado: $lastSync'
                        : 'Lista M3U • Atualizado: $lastSync',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: playlist.isActive
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.textSecondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        playlist.isActive ? 'Ativa' : 'Inativa',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: playlist.isActive
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
          const SizedBox(height: 16),

          // 3. Parental Control Section
          _SettingsSection(
            title: 'Controle Parental',
            children: [
              _SettingsTile(
                icon: parentalState.isEnabled
                    ? Icons.lock_rounded
                    : Icons.lock_open_rounded,
                title: 'Bloqueio de Conteúdo Adulto (+18)',
                subtitle: parentalState.isEnabled
                    ? 'Ativado • Protegido por PIN de 4 dígitos'
                    : 'Desativado • Categorias adultas visíveis sem senha',
                trailing: Switch(
                  value: parentalState.isEnabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: (enabled) async {
                    if (enabled) {
                      _showSetPinDialog(context, ref);
                    } else {
                      final unlocked = await ref
                          .read(parentalControlProvider.notifier)
                          .requestPinUnlock(context);
                      if (unlocked) {
                        ref
                            .read(parentalControlProvider.notifier)
                            .toggleEnabled(false);
                      }
                    }
                  },
                ),
              ),
              if (parentalState.isEnabled)
                _SettingsTile(
                  icon: Icons.pin_rounded,
                  title: 'Alterar PIN de Segurança',
                  subtitle: 'Definir novo código de 4 dígitos',
                  onTap: () => _showSetPinDialog(context, ref),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 4. Audio & Subtitles preferences
          _SettingsSection(
            title: 'Áudio & Legendas',
            children: [
              _SettingsTile(
                icon: Icons.audiotrack_rounded,
                title: 'Áudio Padrão',
                subtitle:
                    'Português (Brasil) • Dublado por padrão quando disponível',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.subtitles_rounded,
                title: 'Legendas Padrão',
                subtitle: 'Desativadas automaticamente em conteúdos dublados',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.key_rounded,
                title: 'API Key OpenSubtitles',
                subtitle: 'Necessária para buscar legendas online (gratuita)',
                onTap: () => _showApiKeyDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 5. General & About section
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
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: l10n.appTitle,
                subtitle: 'v1.0.0 (Android TV & Fire TV Edition)',
                onTap: () {},
              ),
            ],
          ),

          // Maintenance — explicit triggers for background jobs
          _SettingsSection(
            title: 'Manutenção',
            children: [
              _SettingsTile(
                icon: Icons.auto_awesome_rounded,
                title: 'Buscar metadados (TMDB)',
                subtitle: 'Enriquece filmes e séries com pôsteres e sinopses',
                onTap: () => _runMetadataEnrichment(context, ref),
              ),
              SwitchListTile(
                secondary: const Icon(
                  Icons.health_and_safety_rounded,
                  color: AppColors.primary,
                ),
                activeThumbColor: AppColors.primary,
                title: const Text(
                  'Verificação de saúde dos canais',
                  style: TextStyle(fontSize: 14),
                ),
                subtitle: const Text(
                  'Testa a disponibilidade dos streams em segundo plano',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                value: ref.watch(healthCheckEnabledProvider),
                onChanged: (enabled) {
                  final service = ref.read(healthCheckServiceProvider);
                  if (enabled) {
                    service.startBackgroundCheck();
                  } else {
                    service.stop();
                  }
                  ref.read(healthCheckEnabledProvider.notifier).state = enabled;
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Runs TMDB batch enrichment with explicit user consent (moved out of
  /// HomeScreen's build — a network job must not be a render side effect).
  void _runMetadataEnrichment(BuildContext context, WidgetRef ref) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Busca de metadados iniciada...')),
    );
    Future(() async {
      try {
        final service = ref.read(batchEnrichmentProvider);
        await service.runEnrichment(batchSize: 50);
        messenger.showSnackBar(
          const SnackBar(content: Text('Metadados atualizados!')),
        );
      } catch (e) {
        appLogger.w('[Enrichment] Manual run failed: $e');
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Não foi possível concluir a busca agora.'),
          ),
        );
      }
    });
  }

  void _showSetPinDialog(BuildContext context, WidgetRef ref) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.security_rounded,
                color: AppColors.primary, size: 24),
            const SizedBox(width: 10),
            Text('Definir PIN de 4 Dígitos',
                style: AppTypography.title.copyWith(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Escolha um PIN de 4 números para bloquear canais e conteúdos adultos.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 160,
              child: TextField(
                controller: pinController,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 12,
                    fontWeight: FontWeight.bold),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '0000',
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              if (pinController.text.length == 4) {
                ref
                    .read(parentalControlProvider.notifier)
                    .setPin(pinController.text);
                ref.read(parentalControlProvider.notifier).toggleEnabled(true);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Controle parental ativado com sucesso!')),
                );
              }
            },
            child: const Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context, WidgetRef ref) async {
    final keyController = TextEditingController();
    final existingKey = await SubtitleSearchService.getSavedApiKey();
    if (existingKey != null) {
      keyController.text = existingKey;
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.key_rounded, color: AppColors.primary, size: 24),
            const SizedBox(width: 10),
            Text(
              'API Key OpenSubtitles',
              style: AppTypography.title.copyWith(fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Para buscar legendas online, você precisa de uma chave gratuita do OpenSubtitles.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Acesse opensubtitles.com e crie uma conta\n'
              '2. Vá em API Consumers e clique "New Consumer"\n'
              '3. Cole a chave aqui',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: keyController,
              autofocus: true,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Cole sua API Key aqui...',
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (existingKey != null && existingKey.isNotEmpty)
            TextButton(
              onPressed: () async {
                await SubtitleSearchService.clearApiKey();
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('API Key removida')),
                  );
                }
              },
              child: const Text(
                'Remover',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            onPressed: () async {
              final key = keyController.text.trim();
              if (key.isNotEmpty) {
                await SubtitleSearchService.saveApiKey(key);
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'API Key salva! Busca de legendas ativada.',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Salvar',
              style: TextStyle(color: Colors.white),
            ),
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
                color: isFocused ? AppColors.primary : AppColors.textSecondary,
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
