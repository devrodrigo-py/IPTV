import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nebula_iptv/core/utils/platform_detector.dart';
import 'package:nebula_iptv/core/widgets/focusable_widget.dart';
import 'package:nebula_iptv/core/widgets/remote_grid_view.dart';
import 'package:nebula_iptv/features/shared/widgets/content_row.dart';
import 'package:nebula_iptv/features/tv/tv_navigation_shell.dart';

void main() {
  setUp(() => PlatformDetector.overrideIsTv(true));
  tearDown(() => PlatformDetector.overrideIsTv(null));

  testWidgets(
      'menu, long carousel, uneven rows and Back preserve the focused card',
      (tester) async {
    tester.view.physicalSize = const Size(960, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var activations = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: TvNavigationShell(
      destinations: const [
        TvDestination(Icons.home, 'Início'),
        TvDestination(Icons.movie, 'Filmes')
      ],
      selectedIndex: 0,
      onSelected: (_) {},
      onSearch: () {},
      child: ListView(scrollCacheExtent: ScrollCacheExtent.pixels(1000), children: [
        for (var row = 0; row < 3; row++)
          ContentRow(
            title: 'Fila $row',
            cardWidth: 70,
            height: 140,
            items: List.generate(
                row == 1 ? 1 : 20, (col) => ContentRowItem(title: '$row/$col')),
            onItemTap: (_) => activations++,
          ),
      ]),
    ))));
    await tester.pumpAndSettle();
    Future<void> key(LogicalKeyboardKey key) async {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
    }

    await key(LogicalKeyboardKey.arrowRight);
    for (var i = 0; i < 15; i++) {
      await key(LogicalKeyboardKey.arrowRight);
    }
    final remembered = FocusManager.instance.primaryFocus;
    expect(
        remembered?.context?.findAncestorWidgetOfExactType<ContentRow>()?.title,
        'Fila 0');
    await key(LogicalKeyboardKey.arrowDown);
    expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<ContentRow>()
            ?.title,
        'Fila 1');
    await key(LogicalKeyboardKey.arrowUp);
    expect(FocusManager.instance.primaryFocus, remembered);
    await key(LogicalKeyboardKey.escape);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'TV destination 0');
    await key(LogicalKeyboardKey.arrowRight);
    expect(FocusManager.instance.primaryFocus, remembered);
    await key(LogicalKeyboardKey.select);
    expect(activations, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lazy grid traverses 100 rows and stops at horizontal edges',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: RemoteGridView(
      columns: 4,
      itemCount: 402,
      aspectRatio: 2,
      itemBuilder: (context, index) => FocusableWidget(
          autofocus: index == 0,
          onPressed: () {},
          builder: (context, focused) => Text('Item $index')),
    ))));
    await tester.pumpAndSettle();
    for (var i = 0; i < 100; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    final focus = FocusManager.instance.primaryFocus;
    expect(
        find.descendant(
            of: find.byWidget(focus!.context!.widget),
            matching: find.text('Item 400')),
        findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    final last = FocusManager.instance.primaryFocus;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, last);
    expect(tester.takeException(), isNull);
  });
}
