/// Normalizes user-typed server/playlist URLs.
///
/// IPTV panels are overwhelmingly plain HTTP, and users routinely type
/// `host:port` without a scheme — `Uri` then treats the host as the scheme
/// and the request goes to a nonsense path (surfacing as 404). A missing
/// scheme defaults to `http://`; explicit `https://` is preserved.
extension ServerUrlNormalization on String {
  String normalizeServerUrl() {
    var url = trim();
    if (url.isEmpty) return url;
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (!url.contains('://')) {
      url = 'http://$url';
    }
    return url;
  }
}
