import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nebula_iptv/app/router/app_router.dart';
import 'package:nebula_iptv/core/theme/app_theme.dart';
import 'package:nebula_iptv/core/utils/platform_detector.dart';
import 'package:nebula_iptv/core/widgets/focusable_widget.dart';
import 'package:nebula_iptv/l10n/app_localizations.dart';

/// Root application widget.
class NebulaApp extends StatelessWidget {
  const NebulaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Nebula IPTV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      shortcuts: RemoteKeys.shortcuts,
      builder: (context, child) => Actions(
        actions: {
          RemoteBackIntent: CallbackAction<RemoteBackIntent>(onInvoke: (_) {
            final focusedContext = FocusManager.instance.primaryFocus?.context;
            if (focusedContext != null) {
              Navigator.maybeOf(focusedContext)?.maybePop();
            }
            return null;
          })
        },
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            navigationMode: PlatformDetector.isTv(context)
                ? NavigationMode.directional
                : NavigationMode.traditional,
          ),
          child: FocusTraversalGroup(
              policy: AppFocusTraversalPolicy(), child: child!),
        ),
      ),
      routerConfig: appRouter,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      locale: const Locale('pt', 'BR'),
    );
  }
}
