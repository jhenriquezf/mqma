import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// Nota: import circular controlado (api_client ↔ auth_provider).
// Dart lo permite porque las referencias mutuas son solo dentro de
// cuerpos de funciones, no en declaraciones top-level.
import '../../features/auth/presentation/providers/auth_provider.dart'
    show authStateProvider;

// Android emulator  → 10.0.2.2 (alias del host en AVD)
// iOS simulator     → --dart-define=API_URL=http://localhost:8000/api/v1
// Dispositivo físico → --dart-define=API_URL=http://192.168.x.x:8000/api/v1
const _baseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:8000/api/v1',
);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    headers: {'Content-Type': 'application/json'},
  ));
  dio.interceptors.add(AuthInterceptor(ref));
  return dio;
});

class AuthInterceptor extends Interceptor {
  final _storage = const FlutterSecureStorage();
  final Ref _ref;

  AuthInterceptor(this._ref);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        final token = await _storage.read(key: 'access_token');
        err.requestOptions.headers['Authorization'] = 'Bearer $token';
        final response = await Dio().fetch(err.requestOptions);
        return handler.resolve(response);
      }
      // Refresh falló → forzar logout sin usar Dio (evita recursión).
      // forceLogout() actualiza authStateProvider → el router detecta
      // isLoggedIn=false y redirige a /auth/login automáticamente.
      _ref.read(authStateProvider.notifier).forceLogout();
    }
    handler.next(err);
  }

  Future<bool> _refreshToken() async {
    try {
      final refresh = await _storage.read(key: 'refresh_token');
      if (refresh == null) return false;
      final response = await Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      )).post('$_baseUrl/auth/token/refresh/', data: {'refresh': refresh});
      await _storage.write(key: 'access_token', value: response.data['access']);
      return true;
    } catch (_) {
      return false;
    }
  }
}
