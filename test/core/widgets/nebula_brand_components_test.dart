import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nebula_iptv/core/theme/app_theme.dart';
import 'package:nebula_iptv/core/widgets/empty_view.dart';
import 'package:nebula_iptv/core/widgets/live_indicator.dart';
import 'package:nebula_iptv/core/widgets/nebula_focus_ring.dart';
import 'package:nebula_iptv/features/player/widgets/nebula_buffering_indicator.dart';
import 'package:nebula_iptv/l10n/app_localizations.dart';

final _ringFinder = find.byWidgetPredicate(
  (w) => w is CustomPaint && w.foregroundPainter is NebulaFocusRingPainter,
);

void main() {
  Widget app(Widget child) => MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  group('NebulaBufferingIndicator', () {
    testWidgets('stays hidden during grace period and appears after it',
        (tester) async {
      await tester.pumpWidget(
        app(
          const NebulaBufferingIndicator(
            size: 72,
            gracePeriod: Duration(seconds: 2),
          ),
        ),
      );

      // Durante o grace period: invisível (opacity 0), sem piscar.
      final opacityFinder = find.byType(AnimatedOpacity);
      expect(opacityFinder, findsOneWidget);
      expect(
        tester.widget<AnimatedOpacity>(opacityFinder).opacity,
        0,
      );

      // Após o grace period: visível, com o triângulo desenhado.
      await tester.pump(const Duration(seconds: 2, milliseconds: 300));
      expect(
        tester.widget<AnimatedOpacity>(opacityFinder).opacity,
        1,
      );
      expect(
        find.byWidgetPredicate((w) => w is CustomPaint && w.painter != null),
        findsWidgets,
      );
    });
  });

  group('NebulaFocusRing', () {
    testWidgets('paints gradient ring only when focused', (tester) async {
      await tester.pumpWidget(
        app(
          const NebulaFocusRing(
            focused: false,
            radius: 12,
            child: SizedBox(width: 100, height: 80),
          ),
        ),
      );
      expect(_ringFinder, findsNothing);

      await tester.pumpWidget(
        app(
          const NebulaFocusRing(
            focused: true,
            radius: 12,
            child: SizedBox(width: 100, height: 80),
          ),
        ),
      );
      final painter = tester.widget<CustomPaint>(_ringFinder).foregroundPainter!
          as NebulaFocusRingPainter;
      expect(painter.strokeWidth, 3);
      expect(painter.radius, 12);
    });
  });

  group('LiveIndicator', () {
    testWidgets('renders dot and optional label', (tester) async {
      await tester.pumpWidget(app(const LiveIndicator()));
      expect(find.byType(LiveIndicator), findsOneWidget);

      await tester.pumpWidget(app(const LiveIndicator(label: 'Ao vivo')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('AO VIVO'), findsOneWidget);
    });
  });

  group('EmptyView', () {
    testWidgets('empty variant shows auroraTeal CTA', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        app(
          EmptyView(
            icon: Icons.favorite_border_rounded,
            message: 'Adicione canais aos favoritos',
            actionLabel: 'Ver Canais',
            onAction: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Ver Canais'), findsOneWidget);
      await tester.tap(find.text('Ver Canais'));
      expect(tapped, isTrue);
    });

    testWidgets('error variant exposes retry and hides action without label',
        (tester) async {
      await tester.pumpWidget(
        app(
          EmptyView(
            icon: Icons.favorite_rounded,
            message: 'Falha ao carregar',
            isError: true,
            actionLabel: 'Tentar novamente',
            onAction: () {},
          ),
        ),
      );

      expect(find.text('Tentar novamente'), findsOneWidget);

      await tester.pumpWidget(app(const EmptyView(message: 'Sem conteúdo')));
      expect(find.byType(FilledButton), findsNothing);
    });
  });
}
