/// Stable presentation model; database rows never cross into the home UI.
enum CatalogKind { movie, series, live }

class CatalogItem {
  final int id, playlistId;
  final String title, streamUrl;
  final CatalogKind kind;
  final String? sourceId, posterUrl, backdropUrl, overview, category, year;
  final double? progress;
  final int resumeMs;
  const CatalogItem(
      {required this.id,
      required this.playlistId,
      required this.title,
      required this.streamUrl,
      required this.kind,
      this.sourceId,
      this.posterUrl,
      this.backdropUrl,
      this.overview,
      this.category,
      this.year,
      this.progress,
      this.resumeMs = 0});
  String get kindLabel => switch (kind) {
        CatalogKind.movie => 'Filme',
        CatalogKind.series => 'Série',
        CatalogKind.live => 'Ao vivo',
      };
  String get metadata => [
        kindLabel,
        if (year?.isNotEmpty == true) year!,
        if (category?.isNotEmpty == true) category!.split('|').last.trim()
      ].join(' · ');
}

class CatalogShelf {
  final String title;
  final List<CatalogItem> items;
  CatalogShelf(this.title, List<CatalogItem> items)
      : items = List.unmodifiable(items);
}

class HomeCatalog {
  final List<CatalogItem> featured;
  final List<CatalogShelf> shelves;
  const HomeCatalog({this.featured = const [], this.shelves = const []});
  bool get isEmpty => featured.isEmpty && shelves.isEmpty;
}
