/// Represents a single parsed M3U entry before persistence.
///
/// This is a raw data structure — not a domain entity.
/// Validation and mapping to [Channel] happens in the repository layer.
class M3uEntry {
  final String name;
  final String streamUrl;
  final String? tvgId;
  final String? tvgName;
  final String? logoUrl;
  final String? groupTitle;
  final Map<String, String> extraAttributes;

  const M3uEntry({
    required this.name,
    required this.streamUrl,
    this.tvgId,
    this.tvgName,
    this.logoUrl,
    this.groupTitle,
    this.extraAttributes = const {},
  });

  /// Determines the best sourceId for reconciliation (spec 4.11).
  /// Priority: tvgId > derived key from name+group.
  String? get sourceId {
    if (tvgId != null && tvgId!.isNotEmpty) return tvgId;
    return null;
  }

  /// Whether the entry has a valid stream URL.
  bool get hasValidUrl {
    final uri = Uri.tryParse(streamUrl);
    if (uri == null) return false;
    return uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https' || uri.scheme == 'rtsp');
  }

  @override
  String toString() => 'M3uEntry(name: $name, url: $streamUrl)';
}
