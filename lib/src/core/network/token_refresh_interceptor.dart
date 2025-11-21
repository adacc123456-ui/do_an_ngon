import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:do_an_ngon/src/core/services/local_storage_service.dart';
import 'package:do_an_ngon/src/features/auth/data/models/auth_response.dart';

class TokenRefreshInterceptor extends Interceptor {
  final LocalStorageService _localStorageService;
  final Dio _refreshDio;
  bool _isRefreshing = false;
  final List<_PendingRequest> _pendingRequests = [];

  TokenRefreshInterceptor({
    required LocalStorageService localStorageService,
    required String baseUrl,
  })  : _localStorageService = localStorageService,
        _refreshDio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/json',
            },
          ),
        );

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Chỉ xử lý lỗi 401 (Unauthorized)
    if (err.response?.statusCode == 401) {
      // Bỏ qua nếu đây là request refresh token để tránh vòng lặp vô hạn
      if (err.requestOptions.path.contains('/auth/refresh') ||
          err.requestOptions.path.contains('/auth/login') ||
          err.requestOptions.path.contains('/auth/register')) {
        return handler.next(err);
      }

      // Nếu đang refresh token, thêm request vào hàng đợi
      if (_isRefreshing) {
        return _queueRequest(err, handler);
      }

      // Bắt đầu refresh token
      _isRefreshing = true;

      try {
        final refreshToken = await _localStorageService.getRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) {
          _isRefreshing = false;
          _rejectPendingRequests(err);
          return handler.next(err);
        }

        // Gọi API refresh token
        final response = await _refreshDio.post(
          '/auth/refresh',
          data: {'refreshToken': refreshToken},
        );

        // Parse response
        final data = response.data;
        final payload = data is Map<String, dynamic>
            ? (data['data'] as Map<String, dynamic>? ?? data)
            : data;

        final authResponse = AuthResponse.fromJson(payload as Map<String, dynamic>);

        if (!authResponse.isValid) {
          throw Exception('Invalid refresh token response');
        }

        // Lưu token mới
        await _localStorageService.saveAuthTokens({
          'accessToken': authResponse.accessToken,
          'refreshToken': authResponse.refreshToken,
          if (authResponse.accessExpires != null)
            'accessExpires': authResponse.accessExpires!.toIso8601String(),
          if (authResponse.refreshExpires != null)
            'refreshExpires': authResponse.refreshExpires!.toIso8601String(),
        });

        // Retry request ban đầu với token mới
        final opts = err.requestOptions;
        final clonedOpts = RequestOptions(
          method: opts.method,
          path: opts.path,
          baseUrl: opts.baseUrl,
          queryParameters: opts.queryParameters,
          headers: {
            ...opts.headers,
            'Authorization': 'Bearer ${authResponse.accessToken}',
          },
          data: opts.data,
          extra: opts.extra,
          validateStatus: opts.validateStatus,
          receiveTimeout: opts.receiveTimeout,
          sendTimeout: opts.sendTimeout,
          followRedirects: opts.followRedirects,
          maxRedirects: opts.maxRedirects,
          persistentConnection: opts.persistentConnection,
          requestEncoder: opts.requestEncoder,
          responseDecoder: opts.responseDecoder,
          listFormat: opts.listFormat,
        );

        final retryResponse = await _refreshDio.fetch(clonedOpts);
        _isRefreshing = false;
        _resolvePendingRequests(authResponse.accessToken);

        return handler.resolve(retryResponse);
      } catch (e) {
        _isRefreshing = false;
        _rejectPendingRequests(err);

        // Nếu refresh token thất bại, xóa auth data
        await _localStorageService.clearAuthData();

        if (kDebugMode) {
          debugPrint('🔄 Token refresh failed: $e');
        }

        return handler.next(err);
      }
    }

    return handler.next(err);
  }

  void _queueRequest(DioException err, ErrorInterceptorHandler handler) {
    final completer = Completer<Response>();
    _pendingRequests.add(_PendingRequest(
      requestOptions: err.requestOptions,
      handler: handler,
      completer: completer,
    ));
  }

  void _resolvePendingRequests(String newAccessToken) async {
    for (final pending in _pendingRequests) {
      try {
        final opts = pending.requestOptions;
        final clonedOpts = RequestOptions(
          method: opts.method,
          path: opts.path,
          baseUrl: opts.baseUrl,
          queryParameters: opts.queryParameters,
          headers: {
            ...opts.headers,
            'Authorization': 'Bearer $newAccessToken',
          },
          data: opts.data,
          extra: opts.extra,
          validateStatus: opts.validateStatus,
          receiveTimeout: opts.receiveTimeout,
          sendTimeout: opts.sendTimeout,
          followRedirects: opts.followRedirects,
          maxRedirects: opts.maxRedirects,
          persistentConnection: opts.persistentConnection,
          requestEncoder: opts.requestEncoder,
          responseDecoder: opts.responseDecoder,
          listFormat: opts.listFormat,
        );
        final response = await _refreshDio.fetch(clonedOpts);
        pending.handler.resolve(response);
        pending.completer.complete(response);
      } catch (e) {
        final dioError = e is DioException
            ? e
            : DioException(
                requestOptions: pending.requestOptions,
                error: e,
              );
        pending.handler.reject(dioError);
        if (!pending.completer.isCompleted) {
          pending.completer.completeError(e);
        }
      }
    }
    _pendingRequests.clear();
  }

  void _rejectPendingRequests(DioException err) {
    for (final pending in _pendingRequests) {
      pending.handler.reject(err);
      if (!pending.completer.isCompleted) {
        pending.completer.completeError(err);
      }
    }
    _pendingRequests.clear();
  }
}

class _PendingRequest {
  final RequestOptions requestOptions;
  final ErrorInterceptorHandler handler;
  final Completer<Response> completer;

  _PendingRequest({
    required this.requestOptions,
    required this.handler,
    required this.completer,
  });
}

