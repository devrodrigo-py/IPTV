import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/focusable_widget.dart';
import 'package:nebula_iptv/core/widgets/nebula_cached_image.dart';
import 'package:nebula_iptv/core/widgets/tv_safe_area.dart';
import 'package:nebula_iptv/data/database/database_provider.dart';
import 'package:nebula_iptv/domain/models/catalog_item.dart';
import 'package:nebula_iptv/domain/services/watch_tracking_service.dart';
import 'package:nebula_iptv/features/home/providers/home_provider.dart';
import 'package:nebula_iptv/features/player/player_screen.dart';
import 'package:nebula_iptv/features/series/providers/series_provider.dart';
import 'package:nebula_iptv/features/series/series_detail_screen.dart';
import 'package:nebula_iptv/features/shared/widgets/content_row.dart';
import 'package:nebula_iptv/features/shared/widgets/hero_banner.dart';

final catalogFavoriteProvider = StreamProvider.autoDispose.family<bool, int>(
    (ref, id) => ref
        .watch(databaseProvider)
        .favoritesDao
        .watchFavoriteChannels()
        .map((items) => items.any((item) => item.id == id)));

void openCatalogItem(BuildContext context, CatalogItem item,
    {String? heroTag}) {
  Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => CatalogDetailScreen(item: item, heroTag: heroTag)));
}

Future<void> playCatalogItem(
    BuildContext context, WidgetRef ref, CatalogItem item) async {
  if (item.kind == CatalogKind.series) {
    await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => SeriesDetailScreen(
            series: SeriesItem(
                id: item.id,
                playlistId: item.playlistId,
                name: item.title,
                sourceId: item.sourceId,
                coverUrl: item.posterUrl,
                categoryName: item.category,
                tmdbOverview: item.overview,
                tmdbBackdropUrl: item.backdropUrl))));
  } else if (item.streamUrl.isNotEmpty) {
    await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => PlayerScreen(
            channelName: item.title,
            streamUrl: item.streamUrl,
            logoUrl: item.posterUrl,
            seekToMs: item.resumeMs > 0 ? item.resumeMs : null,
            contentInfo: WatchContentInfo(
                channelId: item.id,
                name: item.title,
                contentType: item.kind == CatalogKind.movie ? 'vod' : 'live',
                thumbnailUrl: item.posterUrl))));
  } else {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Este conteúdo não tem um endereço de reprodução. Atualize sua fonte.')));
  }
  if (context.mounted) ref.invalidate(resumeCatalogProvider);
}

Future<void> showCatalogMenu(
    BuildContext context, WidgetRef ref, CatalogItem item) async {
  final db = ref.read(databaseProvider);
  final saved = await db.favoritesDao.isFavorite(item.id);
  if (!context.mounted) return;
  final change = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
              title: Text(item.title),
              content: Text(saved
                  ? 'Remover este título da sua lista?'
                  : 'Guardar este título para assistir depois?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar')),
                FilledButton(
                    autofocus: true,
                    onPressed: () => Navigator.pop(context, true),
                    child:
                        Text(saved ? 'Remover da lista' : 'Adicionar à lista')),
              ]));
  if (change != true) return;
  try {
    await db.favoritesDao.toggleFavorite(item.id);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Não foi possível atualizar sua lista. Tente novamente.')));
    }
  }
}

class CatalogDetailScreen extends ConsumerWidget {
  final CatalogItem item;
  final String? heroTag;
  const CatalogDetailScreen({super.key, required this.item, this.heroTag});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorite =
        ref.watch(catalogFavoriteProvider(item.id)).valueOrNull ?? false;
    final related = ref.watch(relatedCatalogProvider(item));
    final poster = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: NebulaCachedImage(
            imageUrl: item.posterUrl,
            width: 100,
            height: 150,
            cacheWidth: 300,
            fit: BoxFit.cover));
    return Scaffold(
        body: TvSafeArea(
            child: FocusTraversalGroup(
      policy: AppFocusTraversalPolicy(),
      child: ListView(scrollCacheExtent: ScrollCacheExtent.pixels(600), children: [
        Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
                autofocus: true,
                tooltip: 'Voltar',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back))),
        HeroBanner(items: [
          HeroBannerItem(
              title: item.title,
              imageUrl: item.backdropUrl ?? item.posterUrl,
              subtitle: item.metadata,
              description: item.overview,
              label: item.kindLabel.toUpperCase(),
              onPlay: () => playCatalogItem(context, ref, item))
        ]),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (heroTag != null)
                Hero(tag: heroTag!, child: poster)
              else
                poster,
              const SizedBox(width: 24),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    OutlinedButton.icon(
                        onPressed: () => showCatalogMenu(context, ref, item),
                        icon: Icon(
                            favorite ? Icons.check_rounded : Icons.add_rounded),
                        label:
                            Text(favorite ? 'Na minha lista' : 'Minha lista')),
                    const SizedBox(height: 16),
                    Text(
                        item.overview?.isNotEmpty == true
                            ? item.overview!
                            : 'A fonte ainda não forneceu uma sinopse para este título.',
                        style: AppTypography.body),
                  ])),
            ])),
        if (related.valueOrNull?.isNotEmpty == true)
          ContentRow(
              title: 'Você também pode gostar',
              items: related.value!
                  .map((item) => ContentRowItem(
                      title: item.title,
                      imageUrl: item.posterUrl,
                      subtitle: item.metadata))
                  .toList(),
              onItemTap: (i) => openCatalogItem(context, related.value![i])),
        if (related.hasError)
          TextButton(
              onPressed: () => ref.invalidate(relatedCatalogProvider(item)),
              child: const Text('Tentar carregar títulos relacionados')),
        const SizedBox(height: 32),
      ]),
    )));
  }
}
