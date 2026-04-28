// lib/presentation/screens/splash/splash_screen.dart
//
// ─── PANTALLA SPLASH ─────────────────────────────────────────────────────────
// Se muestra brevemente al iniciar la app mientras Supabase verifica
// si hay una sesión activa guardada en SecureStorage del dispositivo.
//
// GoRouter maneja el redirect automático:
//   • Si hay sesión → /tasks
//   • Si no hay sesión → /login
//
// Ver: lib/core/router/app_router.dart (redirect guard)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
      return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 16),
            Text(
              'TaskBoard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
