import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/api_client.dart';
import '../router/navigator_key.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Handler de background (obligatorio: función top-level, no closure)
// ─────────────────────────────────────────────────────────────────────────────

@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  // Firebase ya está inicializado cuando se llama este handler.
  // El SO se encarga de mostrar la notificación en la bandeja.
  debugPrint('[FCM BG] ${message.notification?.title}: ${message.notification?.body}');
}

// ─────────────────────────────────────────────────────────────────────────────
// Servicio singleton
// ─────────────────────────────────────────────────────────────────────────────

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  Ref? _ref; // ref del AsyncNotifier — válido durante toda la vida de la app

  /// `true` solo si Firebase se inicializó correctamente en main().
  /// Cuando es `false` (placeholder o sin config) todas las ops FCM son no-op.
  bool _initialized = false;

  // ── Inicialización ─────────────────────────────────────────────────────────

  /// Configura handlers globales. Llamar UNA VEZ en main() después de
  /// Firebase.initializeApp(). No requiere autenticación.
  Future<void> setup() async {
    // Handler de background (app terminada o en segundo plano)
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    // En iOS: mostrar alertas incluso con la app en primer plano
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Mensajes en primer plano → Snackbar personalizado
    FirebaseMessaging.onMessage.listen(_handleForeground);

    // Tap en notificación: app estaba en segundo plano (no terminada)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // Tap en notificación: app estaba terminada → retarda para dejar que
    // el router inicialice
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      Future.delayed(
        const Duration(milliseconds: 800),
        () => _handleTap(initial),
      );
    }

    // Marcar como inicializado SOLO si todo lo anterior tuvo éxito.
    // Con el placeholder de google-services.json setup() lanzará excepción
    // antes de llegar aquí, por lo que _initialized permanecerá false.
    _initialized = true;
  }

  // ── Token FCM ──────────────────────────────────────────────────────────────

  /// Pide permisos y registra el token FCM en el backend.
  /// Llamar después del login exitoso.
  Future<void> registerToken(Ref ref) async {
    if (!_initialized) return; // Firebase con placeholder o sin configurar
    _ref = ref;

    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] Permiso de notificaciones denegado');
      return;
    }

    try {
      // En iOS hay que esperar el APNS token antes del FCM token
      if (Platform.isIOS) await _fcm.getAPNSToken();

      final token = await _fcm.getToken();
      if (token != null) await _sendTokenToBackend(token);
    } catch (e) {
      debugPrint('[FCM] Error obteniendo token: $e');
    }

    // Cuando el token se renueva, re-registrarlo
    _fcm.onTokenRefresh.listen(_sendTokenToBackend);
  }

  /// Elimina el token del backend y lo invalida localmente.
  /// Llamar ANTES de hacer logout.
  Future<void> unregisterToken(Ref ref) async {
    if (!_initialized) return; // Firebase con placeholder o sin configurar
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        final dio = ref.read(dioProvider);
        await dio.delete('/users/device-token/', data: {'token': token});
      }
      await _fcm.deleteToken();
      debugPrint('[FCM] Token eliminado');
    } catch (e) {
      debugPrint('[FCM] Error eliminando token: $e');
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    if (_ref == null) return;
    try {
      final dio = _ref!.read(dioProvider);
      final platform = Platform.isIOS ? 'ios' : 'android';
      await dio.post(
        '/users/device-token/',
        data: {'token': token, 'platform': platform},
      );
      debugPrint('[FCM] Token registrado ✓ (${token.substring(0, 12)}…)');
    } catch (e) {
      debugPrint('[FCM] Error registrando token: $e');
    }
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  void _handleForeground(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final context = appNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notification.title != null)
              Text(
                notification.title!,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            if (notification.body != null)
              Text(notification.body!, style: const TextStyle(fontSize: 13)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Ver',
          onPressed: () => _handleTap(message),
        ),
      ),
    );
  }

  void _handleTap(RemoteMessage message) {
    final type = message.data['type'];
    final eventId = message.data['event_id'];

    final context = appNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    switch (type) {
      case 'group_ready':
        // Navega directo a la pantalla de la mesa confirmada
        if (eventId != null) GoRouter.of(context).go('/events/$eventId/group');
      case 'reminder':
        // Muestra el detalle del evento
        if (eventId != null) GoRouter.of(context).go('/events/$eventId');
      case 'review_request':
        // Abre la pantalla de valoración
        if (eventId != null) GoRouter.of(context).go('/review/$eventId');
    }
  }
}
