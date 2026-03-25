import 'package:flutter/material.dart';

/// Clave global del Navigator raíz.
/// Declarada en archivo propio para evitar imports circulares:
/// api_client ← navigator_key → app_router → auth_provider → api_client
final appNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
