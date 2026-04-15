// lib/domain/repositories/i_auth_repository.dart
//
// ─── CONTRATO (Interfaz) ─────────────────────────────────────────────────────
// Define QUÉ operaciones de autenticación existen, sin decir CÓMO se hacen.
//
// Beneficios de este patrón:
//   1. El ViewModel depende de la interfaz, no de la implementación concreta.
//   2. Puedes intercambiar Supabase por Firebase sin tocar el ViewModel.
//   3. En pruebas, puedes pasar un mock que implemente esta interfaz.
//
// Implementación real: data/repositories/auth_repository.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:supabase_flutter/supabase_flutter.dart' show User;
import '../entities/user_profile.dart';

/// Contrato para todas las operaciones de autenticación.
abstract interface class IAuthRepository {
  /// Flujo reactivo que emite el usuario actual cada vez que cambia
  /// (login, logout, token refreshed). Usado en GoRouter para redireccionar.
  Stream<User?> get authStateChanges;

  /// Usuario actualmente autenticado. Null si no hay sesión activa.
  User? get currentUser;

  /// Inicia sesión con email y contraseña.
  /// Lanza [AuthException] si las credenciales son incorrectas.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  /// Registra un nuevo usuario con email y contraseña.
  /// Crea automáticamente el perfil en la tabla `profiles`.
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  });

  /// Inicia sesión con OAuth de Google.
  /// Abre el navegador/WebView con la pantalla de autorización de Google.
  Future<void> signInWithGoogle();

  /// Inicia sesión con OAuth de GitHub.
  /// Abre el navegador/WebView con la pantalla de autorización de GitHub.
  Future<void> signInWithGithub();

  /// Cierra la sesión actual e invalida el token JWT.
  Future<void> signOut();

  /// Obtiene el perfil completo del usuario autenticado.
  Future<UserProfile> getProfile();

  /// Actualiza los datos del perfil (nombre, avatar).
  Future<UserProfile> updateProfile({
    String? fullName,
    String? avatarUrl,
  });
}
