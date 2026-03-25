import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/notification_service.dart';

class AuthState {
  final bool isLoggedIn;
  final bool isOnboarded;
  final String? email;
  const AuthState({this.isLoggedIn = false, this.isOnboarded = false, this.email});
  AuthState copyWith({bool? isLoggedIn, bool? isOnboarded, String? email}) => AuthState(
    isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    isOnboarded: isOnboarded ?? this.isOnboarded,
    email: email ?? this.email,
  );
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  final _storage = const FlutterSecureStorage();

  @override
  Future<AuthState> build() async {
    final token = await _storage.read(key: 'access_token');
    // Usamos el cache local para el arranque rápido; login() siempre sincroniza con backend
    final onboarded = await _storage.read(key: 'onboarding_complete');
    if (token == null) return const AuthState();
    return AuthState(isLoggedIn: true, isOnboarded: onboarded == 'true');
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post(
        '/auth/login/',
        data: {'email': email, 'password': password},
      );
      await _storage.write(key: 'access_token', value: response.data['access']);
      await _storage.write(key: 'refresh_token', value: response.data['refresh']);

      // Fuente de verdad: consultar backend para onboarding_complete del usuario
      // (evita que el flag de un usuario anterior afecte al nuevo)
      bool isOnboarded = false;
      try {
        final meResponse = await dio.get('/users/me/');
        final profile = meResponse.data['profile'];
        isOnboarded = profile != null && (profile['onboarding_complete'] == true);
        // Actualizar cache local con el valor real del backend
        await _storage.write(
          key: 'onboarding_complete',
          value: isOnboarded ? 'true' : 'false',
        );
      } catch (_) {
        // Si falla la red, usar cache local como fallback
        final cached = await _storage.read(key: 'onboarding_complete');
        isOnboarded = cached == 'true';
      }

      state = AsyncData(AuthState(
        isLoggedIn: true,
        isOnboarded: isOnboarded,
        email: email,
      ));

      // Registrar token FCM en el backend (fire-and-forget)
      NotificationService.instance.registerToken(ref);
    } on DioException catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> register(String email, String password) async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        '/auth/registration/',
        data: {'email': email, 'password1': password, 'password2': password},
      );
      await login(email, password);
    } on DioException catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  /// Guarda los datos del onboarding en el backend y marca como completado.
  /// Retorna null si fue exitoso, o un mensaje de error si falló.
  Future<String?> completeOnboarding({
    required String name,
    String? stage,
    String? lookingFor,
    List<String> interests = const [],
    String? mbti,
  }) async {
    try {
      final dio = ref.read(dioProvider);

      final tags = interests
          .where((t) => t.trim().isNotEmpty)
          .map((t) => {'tag': t.trim().toLowerCase(), 'category': 'interest'})
          .toList();

      await dio.patch(
        '/users/profile/',
        data: {
          if (name.trim().isNotEmpty) 'name': name.trim(),
          if (stage != null) 'stage': stage,
          if (lookingFor != null) 'looking_for': lookingFor,
          if (mbti != null) 'mbti': mbti,
          'onboarding_complete': true,
          if (tags.isNotEmpty) 'tags': tags,
        },
      );

      // Actualizar cache local y estado
      await _storage.write(key: 'onboarding_complete', value: 'true');
      state = AsyncData(state.value!.copyWith(isOnboarded: true));
      return null; // éxito
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ??
          e.response?.data?.toString() ??
          'Error al guardar el perfil';
      return msg.toString();
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  Future<void> logout() async {
    // Eliminar token FCM del backend antes de borrar el JWT
    await NotificationService.instance.unregisterToken(ref);
    await _storage.deleteAll();
    state = const AsyncData(AuthState());
  }

  /// Cierre de sesión ligero llamado desde AuthInterceptor cuando el refresh
  /// falla. NO usa Dio (evita recursión en la cadena del interceptor).
  /// El router reacciona al cambio de estado y redirige a /auth/login.
  void forceLogout() {
    _storage.deleteAll(); // fire-and-forget: no necesitamos await aquí
    state = const AsyncData(AuthState());
  }
}

final authStateProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
