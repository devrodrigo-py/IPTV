/// Search result item — unified across channels, VOD, and series.
class SearchResultItem {
  final int id;
  final int playlistId;
  final String name;
  final String? logoUrl;
  final String? streamUrl;
  final String? groupName;
  final String? sourceId;
  final String sourceType; // 'xtream', 'm3u', 'vod', 'series'

  const SearchResultItem({
    required this.id,
    required this.playlistId,
    required this.name,
    this.logoUrl,
    this.streamUrl,
    this.groupName,
    this.sourceId,
    required this.sourceType,
  });

  bool get isLive => sourceType == 'xtream' || sourceType == 'm3u';
  bool get isVod => sourceType == 'vod';
  bool get isSeries => sourceType == 'series';
}

/// Grouped search results.
class SearchResults {
  final List<SearchResultItem> channels;
  final List<SearchResultItem> vod;
  final List<SearchResultItem> series;
  final String query;

  const SearchResults({
    this.channels = const [],
    this.vod = const [],
    this.series = const [],
    this.query = '',
  });

  bool get isEmpty => channels.isEmpty && vod.isEmpty && series.isEmpty;
  int get totalCount => channels.length + vod.length + series.length;
}
