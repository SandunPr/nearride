import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../services/token_store.dart';

class ApiClient {
  ApiClient(this.tokens) {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokens.access();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode != 401 ||
              error.requestOptions.extra['retried'] == true) {
            return handler.next(error);
          }

          try {
            final accessToken = await (_refreshFuture ??= _refreshSession());
            if (accessToken == null) return handler.next(error);

            final request = error.requestOptions;
            request.extra['retried'] = true;
            request.headers['Authorization'] = 'Bearer $accessToken';
            handler.resolve(await dio.fetch(request));
          } catch (_) {
            handler.next(error);
          } finally {
            _refreshFuture = null;
          }
        },
      ),
    );
  }

  late final Dio dio;
  final TokenStore tokens;
  Future<String?>? _refreshFuture;

  Future<String?> _refreshSession() async {
    final refreshToken = await tokens.refresh();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final response = await Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Accept': 'application/json'},
        ),
      ).post('/auth/refresh', data: {'refreshToken': refreshToken});
      await tokens.save(
        Map<String, dynamic>.from(response.data['data']['session'] as Map),
      );
      return tokens.access();
    } on DioException catch (error) {
      // Only an explicitly rejected refresh token ends the local session.
      // Connection and server errors should not log the user out.
      if (error.response?.statusCode == 401) await tokens.clear();
      rethrow;
    }
  }
}
