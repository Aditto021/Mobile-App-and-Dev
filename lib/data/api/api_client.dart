/// MODULE: API client (Dio) — talks to the FeriWala server: base URL,
/// timeouts, the sign-in token header, and one error type for the screens.
///
/// Contains: ApiConfig, ApiException, ApiClient.
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Where the server lives. Set it at build time:
///   flutter run --dart-define=API_URL=http://192.168.0.10:8090
/// `API_URL=off` runs the app with no server at all.
abstract final class ApiConfig {
  static const _fromBuild = String.fromEnvironment('API_URL');
  static const port = 8090;

  /// null means: no server, work on the device only.
  static String? get baseUrl {
    if (_fromBuild == 'off') return null;
    if (_fromBuild.isNotEmpty) return _fromBuild;
    if (kIsWeb) {
      // Same machine that serves the web app.
      final host = Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
      return 'http://$host:$port';
    }
    // The Android emulator reaches the computer at 10.0.2.2.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$port';
    }
    return 'http://localhost:$port';
  }
}

/// Anything that went wrong talking to the server, in words a shopper can
/// read. [offline] means the server could not be reached at all.
class ApiException implements Exception {
  final String message;
  final int? status;
  final String? code;
  final bool offline;
  const ApiException(
    this.message, {
    this.status,
    this.code,
    this.offline = false,
  });

  @override
  String toString() => message;
}

class ApiClient {
  final Dio dio;

  /// Sign-in token, sent as `Authorization: Bearer …` when set.
  String? token;

  ApiClient(String baseUrl, {HttpClientAdapter? adapter})
    : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
        ),
      ) {
    if (adapter != null) dio.httpClientAdapter = adapter;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final t = token;
          if (t != null && !options.headers.containsKey('authorization')) {
            options.headers['authorization'] = 'Bearer $t';
          }
          handler.next(options);
        },
      ),
    );
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => dio.get<dynamic>(path, queryParameters: query));

  Future<dynamic> post(String path, [Object? body, Options? options]) =>
      _send(() => dio.post<dynamic>(path, data: body, options: options));

  Future<dynamic> put(String path, [Object? body]) =>
      _send(() => dio.put<dynamic>(path, data: body));

  Future<dynamic> patch(String path, [Object? body]) =>
      _send(() => dio.patch<dynamic>(path, data: body));

  Future<dynamic> delete(String path) => _send(() => dio.delete<dynamic>(path));

  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    try {
      return (await request()).data;
    } on DioException catch (e) {
      throw _explain(e);
    }
  }

  static ApiException _explain(DioException e) {
    final response = e.response;
    if (response == null) {
      return const ApiException(
        'Can\'t reach the FeriWala server. Check your connection.',
        offline: true,
      );
    }
    final data = response.data;
    final error = data is Map ? data['error'] : null;
    if (error is Map && error['message'] is String) {
      return ApiException(
        error['message'] as String,
        status: response.statusCode,
        code: error['code'] as String?,
      );
    }
    return ApiException(
      'The server replied with an error (${response.statusCode}).',
      status: response.statusCode,
    );
  }
}
