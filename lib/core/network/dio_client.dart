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

  final int maxGetAttempts;
  final Duration retryDelay;
  DioClient({String? baseUrl, Dio? dio, this.maxGetAttempts = 3,
    this.retryDelay = const Duration(milliseconds: 350)}) : assert(maxGetAttempts > 0) {
    _dio = dio ?? Dio(
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
      final response = await _getWithRetry<T>(path, queryParameters, options);
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

  Future<Response<T>> _getWithRetry<T>(String path, Map<String, dynamic>? query, Options? options) async {
    for (var attempt = 1; ; attempt++) {
      try { return await _dio.get<T>(path, queryParameters: query, options: options); }
      on DioException catch (error) {
        final transient = error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout || error.type == DioExceptionType.receiveTimeout ||
          const {502, 503, 504}.contains(error.response?.statusCode);
        if (!transient || attempt >= maxGetAttempts) rethrow;
        await Future<void>.delayed(retryDelay * attempt);
      }
    }
  }

  /// Downloads to [savePath] (streaming — o corpo nunca vive inteiro na RAM).
  /// Usado pelo EPG: guias XMLTV chegam a dezenas de MB.
  Future<Result<void>> download(
    String url,
    String savePath, {
    Options? options,
  }) async {
    try {
      await _dio.download(url, savePath, options: options);
      return const Success(null);
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

    // Response bodies and stream paths can include credentials.
    appLogger.w('http.failure status=$statusCode');

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
  String _sanitizePath(String path) => Uri.tryParse(path)?.host ?? '[invalid URL]';
}
