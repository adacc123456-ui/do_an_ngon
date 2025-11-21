import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:do_an_ngon/src/core/services/local_storage_service.dart';
import 'package:do_an_ngon/src/core/network/logging_interceptor.dart';
import 'package:do_an_ngon/src/core/network/token_refresh_interceptor.dart';

class ApiClient {
  late final Dio _dio;
  final LocalStorageService _localStorageService;

  ApiClient({required LocalStorageService localStorageService})
      : _localStorageService = localStorageService {
    final baseUrl = _resolveBaseUrl();
    _dio = Dio(
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

    // Thêm interceptor để tự động refresh token khi gặp 401
    _dio.interceptors.add(
      TokenRefreshInterceptor(
        localStorageService: _localStorageService,
        baseUrl: baseUrl,
      ),
    );

    // Thêm interceptor để thêm token vào header
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _localStorageService.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));

    if (kDebugMode) {
      _dio.interceptors.add(LoggingInterceptor());
    }
  }

  Dio get dio => _dio;

  String _resolveBaseUrl() {
    try {
      if (dotenv.isInitialized) {
        final value = dotenv.maybeGet('API_BASE_URL');
        if (value != null && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    } catch (e) {
      debugPrint('⚠️  Không thể đọc API_BASE_URL từ .env: $e');
    }
    return 'http://172.20.10.6:8080/api';
  }
}
