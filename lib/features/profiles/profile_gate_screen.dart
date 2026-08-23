import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';
import 'package:nebula_iptv/features/profiles/profile_selection_screen.dart';
import 'package:nebula_iptv/features/profiles/providers/profile_provider.dart';
import 'package:nebula_iptv/features/shell/shell_screen.dart';

/// Gate screen that decides whether to show profile selection or go to app.
///
/// - If only 1 profile exists → skip selection, go directly to ShellScreen.
/// - If 2+ profiles → show ProfileSelectionScreen first.
class ProfileGateScreen extends ConsumerStatefulWidget {
  const ProfileGateScreen({super.key});

  @override
  ConsumerState<ProfileGateScreen> createState() => _ProfileGateScreenState();
}

class _ProfileGateScreenState extends ConsumerState<ProfileGateScreen> {
  bool _profileSelected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureDefaultProfile();
    });
  }

  Future<void> _ensureDefaultProfile() async {
    final db = ref.read(databaseProvider);
    await db.profileDao.ensureDefaultProfile();
  }

  @override
  Widget build(BuildContext context) {
    // If profile already selected, show the app
    if (_profileSelected) {
      return const ShellScreen();
    }

    final shouldShow = ref.watch(shouldShowProfileSelectionProvider);

    return shouldShow.when(
      data: (show) {
        if (!show) {
          // Only 1 profile — skip selector, use default
          return const ShellScreen();
        }
        return ProfileSelectionScreen(
          onProfileSelected: () {
            setState(() => _profileSelected = true);
          },
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const ShellScreen(),
    );
  }
}
