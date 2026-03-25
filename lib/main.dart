import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase (graceful: la app arranca aunque falle).
  // Requiere:  android/app/google-services.json  (real, no placeholder)
  //            ios/Runner/GoogleService-Info.plist
  // Con el placeholder las notificaciones push no funcionarán, pero el
  // resto de la app (pago, matching, perfil) funciona con normalidad.
  try {
    await Firebase.initializeApp();
    await NotificationService.instance.setup();
  } catch (e) {
    debugPrint('[Firebase] Iniciación omitida: $e');
  }

  runApp(const ProviderScope(child: MqmaApp()));
}

class MqmaApp extends ConsumerWidget {
  const MqmaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'MQMA',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
