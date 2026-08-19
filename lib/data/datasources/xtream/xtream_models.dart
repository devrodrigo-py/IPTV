/// Models for Xtream Codes API responses.
library;

/// These are raw DTOs — mapping to domain entities happens in the repository.
/// Authentication response from the Xtream API.
class XtreamAuthResponse {
  final XtreamUserInfo userInfo;
  final XtreamServerInfo serverInfo;

  const XtreamAuthResponse({
    required this.userInfo,
    required this.serverInfo,
  });

  factory XtreamAuthResponse.fromJson(Map<String, dynamic> json) {
    return XtreamAuthResponse(
      userInfo: XtreamUserInfo.fromJson(
        json['user_info'] as Map<String, dynamic>,
      ),
      serverInfo: XtreamServerInfo.fromJson(
        json['server_info'] as Map<String, dynamic>,
      ),
    );
  }
}

/// User info from Xtream authentication.
class XtreamUserInfo {
  final String username;
  final String status;
  final int auth;
  final String? expDate;
  final String? maxConnections;
  final String? activeCons;

  const XtreamUserInfo({
    required this.username,
    required this.status,
    required this.auth,
    this.expDate,
    this.maxConnections,
    this.activeCons,
  });

  factory XtreamUserInfo.fromJson(Map<String, dynamic> json) {
    return XtreamUserInfo(
      username: json['username']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      auth: _parseInt(json['auth']),
      expDate: json['exp_date']?.toString(),
      maxConnections: json['max_connections']?.toString(),
      activeCons: json['active_cons']?.toString(),
    );
  }

  /// Whether the account is authenticated.
  bool get isAuthenticated => auth == 1;

  /// Whether the account is expired.
  bool get isExpired {
    if (expDate == null || expDate!.isEmpty) return false;
    try {
      final expTimestamp = int.parse(expDate!);
      final expDateTime =
          DateTime.fromMillisecondsSinceEpoch(expTimestamp * 1000);
      return DateTime.now().isAfter(expDateTime);
    } catch (_) {
      return false;
    }
  }

  /// Whether max connections are exceeded.
  bool get isConnectionLimitReached {
    if (maxConnections == null || activeCons == null) return false;
    try {
      final max = int.parse(maxConnections!);
      final active = int.parse(activeCons!);
      return active >= max;
    } catch (_) {
      return false;
    }
  }
}

/// Server info from Xtream authentication.
class XtreamServerInfo {
  final String url;
  final String port;
  final String httpsPort;
  final String serverProtocol;

  const XtreamServerInfo({
    required this.url,
    required this.port,
    required this.httpsPort,
    required this.serverProtocol,
  });

  factory XtreamServerInfo.fromJson(Map<String, dynamic> json) {
    return XtreamServerInfo(
      url: json['url']?.toString() ?? '',
      port: json['port']?.toString() ?? '',
      httpsPort: json['https_port']?.toString() ?? '',
      serverProtocol: json['server_protocol']?.toString() ?? 'http',
    );
  }

  /// Constructs base URL from server info.
  String get baseUrl {
    final protocol = serverProtocol.isNotEmpty ? serverProtocol : 'http';
    final effectivePort = protocol == 'https' ? httpsPort : port;
    return '$protocol://$url:$effectivePort';
  }
}

/// A live stream category from Xtream API.
class XtreamCategory {
  final String categoryId;
  final String categoryName;

  const XtreamCategory({
    required this.categoryId,
    required this.categoryName,
  });

  factory XtreamCategory.fromJson(Map<String, dynamic> json) {
    return XtreamCategory(
      categoryId: json['category_id']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ?? '',
    );
  }
}

/// A live stream entry from Xtream API.
class XtreamLiveStream {
  final int streamId;
  final String name;
  final String? streamIcon;
  final String? epgChannelId;
  final String? categoryId;
  final String? containerExtension;

  const XtreamLiveStream({
    required this.streamId,
    required this.name,
    this.streamIcon,
    this.epgChannelId,
    this.categoryId,
    this.containerExtension,
  });

  factory XtreamLiveStream.fromJson(Map<String, dynamic> json) {
    return XtreamLiveStream(
      streamId: _parseInt(json['stream_id']),
      name: json['name']?.toString() ?? '',
      streamIcon: json['stream_icon']?.toString(),
      epgChannelId: json['epg_channel_id']?.toString(),
      categoryId: json['category_id']?.toString(),
      containerExtension: json['container_extension']?.toString(),
    );
  }
}

/// Safely parses an int from dynamic (may be String or int).
int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
