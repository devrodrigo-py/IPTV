import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';

/// Dialog for creating/editing a profile.
class ProfileEditDialog extends StatefulWidget {
  final String? initialName;
  final String? initialIcon;
  final String? initialColor;

  const ProfileEditDialog({
    super.key,
    this.initialName,
    this.initialIcon,
    this.initialColor,
  });

  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<ProfileEditDialog> {
  late final TextEditingController _nameController;
  late String _selectedIcon;
  late String _selectedColor;

  static const _availableIcons = [
    ('person', Icons.person_rounded),
    ('child', Icons.child_care_rounded),
    ('star', Icons.star_rounded),
    ('pets', Icons.pets_rounded),
    ('sports', Icons.sports_esports_rounded),
    ('music', Icons.music_note_rounded),
    ('movie', Icons.movie_rounded),
    ('school', Icons.school_rounded),
  ];

  static const _availableColors = [
    '#7B2FF7', // Purple (primary)
    '#E53935', // Red
    '#43A047', // Green
    '#1E88E5', // Blue
    '#FB8C00', // Orange
    '#8E24AA', // Deep Purple
    '#00ACC1', // Cyan
    '#F4511E', // Deep Orange
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _selectedIcon = widget.initialIcon ?? 'person';
    _selectedColor = widget.initialColor ?? '#7B2FF7';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialName != null;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        isEditing ? 'Editar perfil' : 'Novo perfil',
        style: AppTypography.title,
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name field
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                hintText: 'Ex: João, Kids, Trabalho...',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              maxLength: 20,
            ),

            const SizedBox(height: 16),

            // Color picker
            Text('Cor', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableColors.map((hex) {
                final color = _parseColor(hex);
                final isSelected = hex == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hex),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Icon picker
            Text('Ícone', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableIcons.map((entry) {
                final (name, icon) = entry;
                final isSelected = name == _selectedIcon;
                final color = _parseColor(_selectedColor);
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = name),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.2) : AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: color, width: 2)
                          : Border.all(color: AppColors.divider),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? color : AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Preview
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _parseColor(_selectedColor).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _parseColor(_selectedColor),
                    width: 2,
                  ),
                ),
                child: Icon(
                  _getIconData(_selectedIcon),
                  size: 40,
                  color: _parseColor(_selectedColor),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(context, {
              'name': name,
              'icon': _selectedIcon,
              'color': _selectedColor,
            });
          },
          child: Text(isEditing ? 'Salvar' : 'Criar'),
        ),
      ],
    );
  }

  Color _parseColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  IconData _getIconData(String name) {
    for (final entry in _availableIcons) {
      if (entry.$1 == name) return entry.$2;
    }
    return Icons.person_rounded;
  }
}
