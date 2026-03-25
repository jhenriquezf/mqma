import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    ref.read(authStateProvider).when(
      data: (s) {
        if (!s.isLoggedIn) {
          context.go('/auth/login');
        } else if (!s.isOnboarded) {
          context.go('/onboarding');
        } else {
          context.go('/events');
        }
      },
      loading: () => context.go('/auth/login'),
      error: (_, __) => context.go('/auth/login'),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF1D9E75),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('MQMA', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w700, letterSpacing: -1)),
          const SizedBox(height: 8),
          Text('Mesa que más aplaude', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16)),
        ],
      ),
    ),
  );
}
