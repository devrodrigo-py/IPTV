import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nebula_iptv/core/widgets/loading_view.dart';
import 'package:nebula_iptv/domain/models/catalog_item.dart';
import 'package:nebula_iptv/features/home/home_screen.dart';
import 'package:nebula_iptv/features/home/providers/home_provider.dart';
import 'package:nebula_iptv/features/shared/widgets/hero_banner.dart';

const movie = CatalogItem(id: 1, playlistId: 1, title: 'Uma nova história',
  streamUrl: 'https://example.invalid/movie', kind: CatalogKind.movie,
  category: 'Aventura', year: '2026', overview: 'Uma viagem inesperada que muda tudo.');
Widget app(Stream<HomeCatalog> catalog) => ProviderScope(overrides: [
  homeCatalogProvider.overrideWith((ref) => catalog),
  myListCatalogProvider.overrideWith((ref) => Stream.value([])),
  resumeCatalogProvider.overrideWith((ref) => Stream.value([])),
], child: const MaterialApp(home: Scaffold(body: HomeScreen())));
void main() {
  testWidgets('loading does not pretend the catalogue is empty', (tester) async {
    final stream = StreamController<HomeCatalog>();
    await tester.pumpWidget(app(stream.stream));
    expect(find.byType(LoadingView), findsOneWidget);
    expect(find.text('Conectar uma fonte'), findsNothing);
    stream.add(const HomeCatalog());
    await tester.pumpAndSettle();
    expect(find.text('Conectar uma fonte'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await stream.close();
  });
  testWidgets('failure has retry rather than onboarding', (tester) async {
    await tester.pumpWidget(app(Stream.error(StateError('database'))));
    await tester.pumpAndSettle();
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.text('Conectar uma fonte'), findsNothing);
  });
  testWidgets('hero and catalogue fit phone and TV widths', (tester) async {
    for (final size in [const Size(400, 800), const Size(960, 540)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(app(Stream.value(HomeCatalog(featured: const [movie],
        shelves: [CatalogShelf('Aventura', const [movie])]))));
      await tester.pumpAndSettle();
      expect(find.byType(HeroBanner), findsOneWidget);
      expect(find.text('Assistir'), findsOneWidget);
      expect(find.text('Mais informações'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
