import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nebula_iptv/core/theme/app_theme.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart'
    show databaseProvider;
import 'package:nebula_iptv/features/shell/shell_screen.dart';
import 'package:nebula_iptv/l10n/app_localizations.dart';

/// Pumps [child] with a fresh in-memory database, closed when the test ends.
///
/// Closing the database avoids drift's "created the database class
/// AppDatabase multiple times" warning across tests. The warning is a
/// test-setup concern: production creates exactly one AppDatabase in
/// bootstrap (see database_provider.dart / bootstrap.dart).
Future<void> pumpTestableWidget(WidgetTester tester, Widget child) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('pt', 'BR')],
        locale: const Locale('pt', 'BR'),
        home: child,
      ),
    ),
  );
}

void main() {
  group('ShellScreen', () {
    testWidgets('renders sidebar on desktop layout', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await pumpTestableWidget(tester, const ShellScreen());
      await tester.pumpAndSettle();

      // NebulaBrand wordmark
      expect(find.text('NEBULA'), findsOneWidget);
      expect(find.text('Início'), findsAtLeast(1));
      expect(find.text('Favoritos'), findsOneWidget);
      expect(find.text('Configurações'), findsOneWidget);
    });

    testWidgets('renders bottom nav on mobile layout', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await pumpTestableWidget(tester, const ShellScreen());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('NEBULA'), findsNothing);
    });

    testWidgets('changes content on nav item tap', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await pumpTestableWidget(tester, const ShellScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Configurações'));
      await tester.pumpAndSettle();

      expect(find.text('Perfis'), findsOneWidget);
    });
  });
}
