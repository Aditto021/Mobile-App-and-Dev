/// MODULE: HTTP helpers — JSON responses, request-body parsing, the error
/// type every route throws, and the middleware that turns errors into JSON
/// and lets the web app call the API from another port (CORS).
///
/// Contains: ApiError, jsonOk, readBody, handleErrors, cors.
library;

import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';

/// A problem the client should hear about, sent as
/// `{"error": {"code": ..., "message": ...}}` with [status].
class ApiError implements Exception {
  final int status;
  final String code;
  final String message;
  const ApiError(this.status, this.code, this.message);

  const ApiError.badRequest(String message) : this(400, 'bad_request', message);
  const ApiError.unauthorized([String message = 'Please sign in again.'])
    : this(401, 'unauthorized', message);
  const ApiError.notFound(String message) : this(404, 'not_found', message);
  const ApiError.conflict(String code, String message)
    : this(409, code, message);

  @override
  String toString() => 'ApiError($status, $code, $message)';
}

const _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

Response jsonOk(Object? body, {int status = 200}) =>
    Response(status, body: jsonEncode(body), headers: _jsonHeaders);

/// Largest request body accepted (a full cart is far smaller).
const maxBody = 64 * 1024;

/// Reads the request body as a JSON object; an empty body gives `{}`.
Future<Map<String, dynamic>> readBody(Request request) async {
  final length = request.contentLength;
  if (length != null && length > maxBody) {
    throw const ApiError(413, 'too_large', 'Request body is too large.');
  }
  final raw = await request.readAsString();
  if (raw.length > maxBody) {
    throw const ApiError(413, 'too_large', 'Request body is too large.');
  }
  if (raw.trim().isEmpty) return {};
  try {
    final body = jsonDecode(raw);
    if (body is Map<String, dynamic>) return body;
  } on FormatException {
    // Falls through to the error below.
  }
  throw const ApiError.badRequest('Send a JSON object.');
}

/// Turns [ApiError]s into JSON replies and anything unexpected into a 500.
Middleware handleErrors() =>
    (inner) => (request) async {
      try {
        return await inner(request);
      } on ApiError catch (e) {
        return jsonOk({
          'error': {'code': e.code, 'message': e.message},
        }, status: e.status);
      } catch (e, st) {
        stderr.writeln('${request.method} ${request.requestedUri}: $e\n$st');
        return jsonOk({
          'error': {
            'code': 'server_error',
            'message': 'Something went wrong on our side.',
          },
        }, status: 500);
      }
    };

const _corsHeaders = {
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'access-control-allow-headers': 'authorization, content-type',
  'access-control-max-age': '86400',
};

/// Lets the Flutter web build (served from another port) use the API.
/// Sign-in uses a bearer token, not cookies, so `*` is safe here.
Middleware cors() =>
    (inner) => (request) async {
      if (request.method == 'OPTIONS') {
        return Response(204, headers: _corsHeaders);
      }
      final response = await inner(request);
      return response.change(headers: _corsHeaders);
    };
