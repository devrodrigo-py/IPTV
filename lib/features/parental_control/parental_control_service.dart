import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';

class ParentalControlState {
  final bool isEnabled;
  final String pin;
  final bool isUnlockedForSession;

  const ParentalControlState({
    this.isEnabled = false,
    this.pin = '0000',
    this.isUnlockedForSession = false,
  });

  ParentalControlState copyWith({
    bool? isEnabled,
    String? pin,
    bool? isUnlockedForSession,
  }) {
    return ParentalControlState(
      isEnabled: isEnabled ?? this.isEnabled,
      pin: pin ?? this.pin,
      isUnlockedForSession: isUnlockedForSession ?? this.isUnlockedForSession,
    );
  }
}

class ParentalControlNotifier extends StateNotifier<ParentalControlState> {
  ParentalControlNotifier() : super(const ParentalControlState());

  void toggleEnabled(bool enabled) {
    state = state.copyWith(isEnabled: enabled);
  }

  void setPin(String newPin) {
    if (newPin.length == 4) {
      state = state.copyWith(pin: newPin);
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

    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PinEntryDialog(correctPin: state.pin),
    );

    if (success == true) {
      unlockSession();
      return true;
    }
    return false;
  }
}

final parentalControlProvider =
    StateNotifierProvider<ParentalControlNotifier, ParentalControlState>((ref) {
  return ParentalControlNotifier();
});

class _PinEntryDialog extends StatefulWidget {
  final String correctPin;
  const _PinEntryDialog({required this.correctPin});

  @override
  State<_PinEntryDialog> createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends State<_PinEntryDialog> {
  final _pinController = TextEditingController();
  String _errorText = '';

  void _verify() {
    if (_pinController.text == widget.correctPin) {
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
          Text('Controle Parental', style: AppTypography.title.copyWith(fontSize: 18)),
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
              style: const TextStyle(fontSize: 24, letterSpacing: 12, fontWeight: FontWeight.bold),
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
          child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _verify,
          child: const Text('Desbloquear', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
