import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/data/database/daos/app_settings_dao.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';

class ParentalControlState {
  final bool isEnabled;
  final bool hasPin;

  /// Hash do PIN (sha256 com salt do app). O PIN em claro NUNCA é guardado.
  final String pinHash;
  final bool isUnlockedForSession;

  const ParentalControlState({
    this.isEnabled = false,
    this.hasPin = false,
    this.pinHash = '',
    this.isUnlockedForSession = false,
  });

  ParentalControlState copyWith({
    bool? isEnabled,
    bool? hasPin,
    String? pinHash,
    bool? isUnlockedForSession,
  }) {
    return ParentalControlState(
      isEnabled: isEnabled ?? this.isEnabled,
      hasPin: hasPin ?? this.hasPin,
      pinHash: pinHash ?? this.pinHash,
      isUnlockedForSession: isUnlockedForSession ?? this.isUnlockedForSession,
    );
  }
}

class ParentalControlNotifier extends StateNotifier<ParentalControlState> {
  final Ref _ref;

  ParentalControlNotifier(this._ref) : super(const ParentalControlState()) {
    // Restaura a escolha persistida (o estado anterior vivia só em RAM —
    // o controle parental "sumia" a cada abertura do app).
    Future(() async {
      try {
        final dao = _ref.read(databaseProvider).appSettingsDao;
        final enabled = await dao.getBool(
          kSettingParentalEnabled,
          defaultValue: false,
        );
        final hash = await dao.getString(kSettingParentalPinHash) ?? '';
        state = state.copyWith(
          isEnabled: enabled && hash.isNotEmpty,
          hasPin: hash.isNotEmpty,
          pinHash: hash,
        );
      } catch (e) {
        appLogger.w('[Parental] Falha ao restaurar estado: $e');
      }
    });
  }

  Future<void> toggleEnabled(bool enabled) async {
    state = state.copyWith(isEnabled: enabled);
    try {
      await _ref
          .read(databaseProvider)
          .appSettingsDao
          .setBool(kSettingParentalEnabled, value: enabled);
    } catch (e) {
      appLogger.w('[Parental] Falha ao persistir toggle: $e');
    }
  }

  Future<void> setPin(String newPin) async {
    if (newPin.length != 4) return;
    final hash = _hashPin(newPin);
    state = state.copyWith(pinHash: hash, hasPin: true);
    try {
      await _ref
          .read(databaseProvider)
          .appSettingsDao
          .setString(kSettingParentalPinHash, hash);
    } catch (e) {
      appLogger.w('[Parental] Falha ao persistir PIN: $e');
    }
  }

  void unlockSession() {
    state = state.copyWith(isUnlockedForSession: true);
  }

  void lockSession() {
    state = state.copyWith(isUnlockedForSession: false);
  }

  bool isAdultCategory(String? category) {
    if (category == null || category.isEmpty) return false;
    final lower = category.toLowerCase();
    return lower.contains('+18') ||
        lower.contains('18+') ||
        lower.contains('adult') ||
        lower.contains('xxx') ||
        lower.contains('porn') ||
        lower.contains('erot') ||
        lower.contains('sexy') ||
        lower.contains('hentai');
  }

  Future<bool> requestPinUnlock(BuildContext context) async {
    if (!state.isEnabled || state.isUnlockedForSession) {
      return true;
    }
    if (!state.hasPin) {
      // Sem PIN cadastrado não há o que verificar — bloqueio seria
      // inescapável.
      return true;
    }

    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PinEntryDialog(correctPinHash: state.pinHash),
    );

    if (success == true) {
      unlockSession();
      return true;
    }
    return false;
  }
}

/// sha256 com salt fixo do app. PIN de 4 dígitos tem 10⁴ combinações — o
/// hash existe para o PIN não ficar legível no banco, não para resistir a
/// brute force local.
String _hashPin(String pin) {
  return sha256.convert(utf8.encode('$_kParentalSalt$pin')).toString();
}

const _kParentalSalt = 'nebula-parental-v1';

final parentalControlProvider =
    StateNotifierProvider<ParentalControlNotifier, ParentalControlState>((ref) {
  return ParentalControlNotifier(ref);
});

class _PinEntryDialog extends StatefulWidget {
  final String correctPinHash;
  const _PinEntryDialog({required this.correctPinHash});

  @override
  State<_PinEntryDialog> createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends State<_PinEntryDialog> {
  final _pinController = TextEditingController();
  String _errorText = '';

  void _verify() {
    if (_hashPin(_pinController.text) == widget.correctPinHash) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _errorText = 'PIN incorreto. Tente novamente.';
        _pinController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.lock_rounded, color: AppColors.primary, size: 24),
          const SizedBox(width: 10),
          Text('Controle Parental',
              style: AppTypography.title.copyWith(fontSize: 18)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Digite o PIN de 4 dígitos para desbloquear este conteúdo.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 160,
            child: TextField(
              controller: _pinController,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 24, letterSpacing: 12, fontWeight: FontWeight.bold),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                counterText: '',
                hintText: '••••',
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _verify(),
            ),
          ),
          if (_errorText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _errorText,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _verify,
          child:
              const Text('Desbloquear', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
