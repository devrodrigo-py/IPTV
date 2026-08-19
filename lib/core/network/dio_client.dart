import 'package:dio/dio.dart';
import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/core/result/result.dart';

/// Centralized Dio HTTP client configuration.
///
/// Provides consistent timeout, error handling, and secure logging
/// across all network requests in the application.
class DioClient {
  late final Dio _dio;

  DioClient({String? baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? '',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 15),
      ),
    );

    _dio.interceptors.add(_LoggingInterceptor());
  }

  Dio get dio => _dio;

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
      DioExceptionType.badResponse => 'Erro do servidor (código $statusCode).',
      _ => 'Erro de rede. Tente novamente.',
    };

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
