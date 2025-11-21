import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('➡️  [REQUEST] ${options.method} ${options.uri}');
    debugPrint('Headers: ${options.headers}');
    if (options.data != null) {
      debugPrint('Body: ${_formatData(options.data)}');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('✅  [RESPONSE] ${response.statusCode} ${response.requestOptions.uri}');
    debugPrint('Headers: ${response.headers.map}');
    debugPrint('Body: ${_formatData(response.data)}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('⛔ [ERROR] ${err.response?.statusCode} ${err.requestOptions.uri}');
    debugPrint('Message: ${err.message}');
    if (err.response?.data != null) {
      debugPrint('Body: ${_formatData(err.response?.data)}');
    }
    super.onError(err, handler);
  }

  String _formatData(dynamic data) {
    if (data is String) {
      return data;
    }
    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }
}
