// lib/core/config/env.dart
//
// ─── PROPÓSITO ───────────────────────────────────────────────────────────────
// Centraliza la lectura de variables de entorno del archivo .env.
// Nunca escribas las credenciales directamente en el código fuente.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Punto de acceso único a las variables del archivo .env.
///
/// Uso:
/// ```dart
/// await Env.load();           // llama una sola vez en main()
/// final url = Env.supabaseUrl; // luego úsala donde necesites
/// ```
class Env {
  Env._(); // Constructor privado: no se instancia, solo se usa estáticamente.

  /// Carga el archivo .env desde los assets de Flutter.
  /// Debe llamarse antes de `runApp()` en `main.dart`.
  static Future<void> load() => dotenv.load(fileName: '.env');

  // ── Supabase ────────────────────────────────────────────────────────────────

  /// URL base de tu proyecto Supabase.
  /// Ejemplo: https://xyzcompany.supabase.co
  static String get supabaseUrl => dotenv.env['SUPABASE_URL']!;

  /// Clave anónima (anon key) de tu proyecto Supabase.
  /// Es segura para el cliente porque las políticas RLS la controlan.
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY']!;
}
