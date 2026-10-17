import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/empty_view.dart';
import 'package:nebula_iptv/core/widgets/loading_view.dart';
import 'package:nebula_iptv/domain/models/catalog_item.dart';
import 'package:nebula_iptv/features/catalog/catalog_detail_screen.dart';
import 'package:nebula_iptv/features/home/providers/home_provider.dart';
import 'package:nebula_iptv/features/playlists/playlists_screen.dart';
import 'package:nebula_iptv/features/shared/widgets/content_row.dart';
import 'package:nebula_iptv/features/shared/widgets/hero_banner.dart';
import 'package:nebula_iptv/features/shell/providers/shell_navigation_provider.dart';

/// Home has one bounded discovery stream. Personal shelves subscribe locally,
/// so progress/favorite changes do not rebuild the hero or the whole page.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(homeCatalogProvider);
    return catalog.when(
      loading: () => const LoadingView(),
      error: (_, __) => EmptyView(
          icon: Icons.cloud_off_rounded,
          message:
              'Não foi possível abrir seu catálogo. Vamos tentar novamente?',
          isError: true,
          actionLabel: 'Tentar novamente',
          onAction: () => ref.invalidate(homeCatalogProvider)),
      data: (data) => ListView.builder(
        scrollCacheExtent: ScrollCacheExtent.pixels(900), key: const PageStorageKey('home'),
        padding: const EdgeInsets.only(bottom: 40),
        itemCount: data.shelves.length + 4,
        itemBuilder: (context, index) {
          if (index == 0) {
            if (data.featured.isEmpty) {
              return SizedBox(
                  height: 320,
                  child: EmptyView(
                      icon: Icons.movie_outlined,
                      message:
                          'Sua próxima história começa aqui. Conecte uma fonte de filmes e séries.',
                      actionLabel: 'Conectar uma fonte',
                      onAction: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => const PlaylistsScreen()))));
            }
            return HeroBanner(
                items: data.featured
                    .map((item) => HeroBannerItem(
                          title: item.title,
                          subtitle: item.metadata,
                          description: item.overview,
                          label: 'ESCOLHA SUA PRÓXIMA HISTÓRIA',
                          imageUrl: item.backdropUrl ?? item.posterUrl,
                          onPlay: () => playCatalogItem(context, ref, item),
                          onDetails: () => openCatalogItem(context, item),
                        ))
                    .toList());
          }
          if (index == 1) return const _PersonalShelf(resume: true);
          if (index == 2) return const _PersonalShelf(resume: false);
          if (index == data.shelves.length + 3) {
            return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Acontecendo agora', style: AppTypography.title),
                      OutlinedButton.icon(
                          onPressed: () => ref
                              .read(shellNavigationProvider.notifier)
                              .state = 1,
                          icon: const Icon(Icons.live_tv_rounded),
                          label: const Text('Explorar TV ao vivo')),
                    ]));
          }
          final shelf = data.shelves[index - 3];
          return _Shelf(title: shelf.title, items: shelf.items);
        },
      ),
    );
  }
}

class _PersonalShelf extends ConsumerWidget {
  final bool resume;
  const _PersonalShelf({required this.resume});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = resume ? resumeCatalogProvider : myListCatalogProvider;
    final items = ref.watch(provider);
    return items.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => Padding(
          padding: const EdgeInsets.all(24),
          child: TextButton.icon(
              onPressed: () => ref.invalidate(provider),
              icon: const Icon(Icons.refresh),
              label: Text(
                  'Recarregar ${resume ? 'continuar assistindo' : 'minha lista'}'))),
      data: (items) => items.isEmpty
          ? const SizedBox.shrink()
          : _Shelf(
              title: resume ? 'Continuar assistindo' : 'Minha lista',
              items: items,
              resume: resume),
    );
  }
}

class _Shelf extends ConsumerWidget {
  final String title;
  final List<CatalogItem> items;
  final bool resume;
  const _Shelf({required this.title, required this.items, this.resume = false});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ContentRow(
          title: title,
          items: items
              .map((item) => ContentRowItem(
                    title: item.title,
                    imageUrl: item.posterUrl,
                    subtitle: item.metadata,
                    progress: item.progress,
                    fallbackIcon: item.kind == CatalogKind.live
                        ? Icons.live_tv
                        : Icons.movie_outlined,
                    heroTag: 'home-$title-${item.id}',
                  ))
              .toList(),
          onItemTap: (i) => resume
              ? playCatalogItem(context, ref, items[i])
              : openCatalogItem(context, items[i],
                  heroTag: 'home-$title-${items[i].id}'),
          onItemSecondaryTap: (i, _) =>
              showCatalogMenu(context, ref, items[i])));
}
