import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/core/result/result.dart';

/// Centralized Dio HTTP client configuration.
///
/// Provides consistent timeout, error handling, and secure logging
/// across all network requests in the application.
///
/// TLS policy (ADR-005): invalid certificates are **rejected** by default.
/// A specific host may be opted in — per playlist/source, never globally —
/// via [allowInsecureFor] while a request from that source is in flight.
class DioClient {
  late final Dio _dio;

  /// Hosts explicitly allowed to present invalid/self-signed certificates.
  /// Scoped per client instance; entries are added/removed around the
  /// request that opted in, so unrelated sources are never affected.
  final Set<String> _insecureHosts = {};

  DioClient({String? baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? '',
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 45),
      ),
    );

    if (!kIsWeb) {
      final adapter = _dio.httpClientAdapter;
      if (adapter is IOHttpClientAdapter) {
        adapter.createHttpClient = () {
          final client = HttpClient();
          // Reject invalid certificates unless the host was explicitly
          // opted in by the source being imported (ADR-005).
          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) =>
                  _insecureHosts.contains(host);
          return client;
        };
      }
    }

    _dio.interceptors.add(_LoggingInterceptor());
  }

  Dio get dio => _dio;

  /// Opts in acceptance of invalid/self-signed certificates for the host
  /// of [url]. Must be used only for playlists/sources whose user explicitly
  /// enabled the "trust invalid certificate" option in the UI.
  void allowInsecureFor(String url) {
    final host = _hostOf(url);
    if (host != null) {
      _insecureHosts.add(host);
    }
  }

  /// Removes the insecure-certificate opt-in for the host of [url].
  void disallowInsecureFor(String url) {
    final host = _hostOf(url);
    if (host != null) {
      _insecureHosts.remove(host);
    }
  }

  String? _hostOf(String url) => Uri.tryParse(url)?.host;

  /// Executes a GET request and wraps the result in [Result].
  Future<Result<Response<T>>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return Success(response);
    } on DioException catch (e) {
      return Failure(_mapDioException(e));
    } on Exception catch (e) {
      return Failure(
        UnknownFailure(
          message: 'Erro de conexão inesperado.',
          originalError: e,
        ),
      );
    }
  }

  /// Executes a POST request and wraps the result in [Result].
  Future<Result<Response<T>>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return Success(response);
    } on DioException catch (e) {
      return Failure(_mapDioException(e));
    } on Exception catch (e) {
      return Failure(
        UnknownFailure(
          message: 'Erro de conexão inesperado.',
          originalError: e,
        ),
      );
    }
  }

  /// Maps Dio exceptions to application failures.
  NetworkFailure _mapDioException(DioException exception) {
    final statusCode = exception.response?.statusCode;

    final message = switch (exception.type) {
      DioExceptionType.connectionTimeout =>
        'Tempo de conexão esgotado. Verifique sua internet.',
      DioExceptionType.receiveTimeout =>
        'O servidor demorou para responder. Tente novamente.',
      DioExceptionType.sendTimeout =>
        'Não foi possível enviar a requisição. Tente novamente.',
      DioExceptionType.connectionError => 'Sem conexão com a internet.',
      DioExceptionType.badResponse => switch (statusCode) {
          404 => 'Endereço não encontrado no servidor (404). '
              'Confira a URL da fonte com seu provedor.',
          401 || 403 => 'Acesso negado pelo servidor (código $statusCode). '
              'Verifique as credenciais ou o limite de conexões do plano.',
          _ => 'Erro do servidor (código $statusCode).',
        },
      _ => 'Erro de rede. Tente novamente.',
    };

    // Diagnóstico sem credenciais: host + caminho, status e início do corpo.
    if (exception.type == DioExceptionType.badResponse) {
      final uri = exception.response?.requestOptions.uri;
      final sanitized =
          uri == null ? '<sem uri>' : '${uri.host}:${uri.port}${uri.path}';
      final body = exception.response?.data?.toString() ?? '';
      appLogger.w(
        'HTTP ${statusCode ?? '?'} ← $sanitized '
        '${body.length > 200 ? body.substring(0, 200) : body}',
      );
    }

    return NetworkFailure(
      message: message,
      statusCode: statusCode,
      originalError: exception,
    );
  }
}

/// Interceptor that logs requests/responses without sensitive data.
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Log method and path only — never log full URL with credentials.
    final sanitizedPath = _sanitizePath(options.path);
    appLogger.d('HTTP → ${options.method} $sanitizedPath');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    appLogger.d(
      'HTTP ← ${response.statusCode} '
      '${response.requestOptions.method} '
      '${_sanitizePath(response.requestOptions.path)}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    appLogger.w(
      'HTTP ✗ ${err.type.name} '
      '${err.requestOptions.method} '
      '${_sanitizePath(err.requestOptions.path)}',
    );
    handler.next(err);
  }

  /// Removes query parameters that might contain credentials.
  String _sanitizePath(String path) {
    final uri = Uri.tryParse(path);
    if (uri == null) return path;

    // Remove sensitive query params
    const sensitiveParams = {'username', 'password', 'token', 'key'};
    if (uri.queryParameters.keys
        .any((k) => sensitiveParams.contains(k.toLowerCase()))) {
      return uri.replace(query: '[REDACTED]').toString();
    }
    return path;
  }
}
