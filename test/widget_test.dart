// test/widget_test.dart
//
// ─── NOTA EDUCATIVA ──────────────────────────────────────────────────────────
// El test original del contador fue generado automáticamente por Flutter
// al crear el proyecto con `flutter create`. Ese test referenciaba `MyApp`,
// que existía en el main.dart de ejemplo.
//
// Al reemplazar main.dart con nuestra `TaskBoardApp`, `MyApp` dejó de existir
// y el test rompió. Esto es completamente normal en cualquier proyecto real:
// el código de ejemplo se borra y los tests deben actualizarse.
//
// Este archivo contiene tests básicos que sí corresponden a nuestra app.
// Para correrlos: flutter test
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_supabase_app/presentation/screens/splash/splash_screen.dart';
import 'package:flutter_supabase_app/core/theme/app_theme.dart';

void main() {
  // ── Test de la pantalla Splash ─────────────────────────────────────────────
  // La SplashScreen no depende de Supabase ni de providers, así que
  // podemos renderizarla directamente en un test unitario de widget.
  group('SplashScreen', () {
    testWidgets('muestra el nombre de la app y un indicador de carga', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const SplashScreen(),
        ),
      );

      // Verifica que el nombre de la app esté presente
      expect(find.text('TaskBoard'), findsOneWidget);

      // Verifica que el indicador de progreso esté visible mientras carga
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
