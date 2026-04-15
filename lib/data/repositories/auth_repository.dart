// lib/data/repositories/auth_repository.dart
//
// ─── IMPLEMENTACIÓN ──────────────────────────────────────────────────────────
// Implementación concreta de [IAuthRepository] usando Supabase Auth.
//
// CONCEPTOS SUPABASE que se enseñan aquí:
//   • supabase.auth.signInWithPassword()  → login con email/password
//   • supabase.auth.signUp()              → registro nuevo usuario
//   • supabase.auth.signInWithOAuth()     → login social (Google, GitHub)
//   • supabase.auth.onAuthStateChange     → stream de estado de sesión
//   • supabase.auth.signOut()             → cerrar sesión
//   • supabase.from('profiles').select()  → leer perfil del usuario
//
// JWT / Sesión:
//   Supabase devuelve un access_token (JWT) al autenticarse.
//   El SDK lo guarda en SecureStorage automáticamente y lo refresca solo.
//   Cada petición a la DB incluye el JWT en el header Authorization.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart'
    as app show AuthException, DatabaseException;
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../models/user_profile_model.dart';

class AuthRepository implements IAuthRepository {
  AuthRepository(this._supabase);

  final SupabaseClient _supabase;

  // Alias corto para el cliente de autenticación
  GoTrueClient get _auth => _supabase.auth;

  // ── Auth state ────────────────────────────────────────────────────────────

  @override
  Stream<User?> get authStateChanges {
    // onAuthStateChange emite un AuthState cada vez que el usuario
    // inicia sesión, cierra sesión, o el token se refresca.
    return _auth.onAuthStateChange.map((state) => state.session?.user);
  }

  @override
  User? get currentUser => _auth.currentUser;

  // ── Registro ──────────────────────────────────────────────────────────────

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      // 1. Registra el usuario en Supabase Auth
      final response = await _auth.signUp(
        email: email,
        password: password,
        data: {
          // user_metadata es un campo JSON libre en auth.users
          if (fullName != null) 'full_name': fullName,
        },
      );

      if (response.user == null) {
        throw const app.AuthException(
          'No se pudo crear la cuenta. Intenta con otro correo.',
        );
      }

      // 2. El trigger en la BD crea el perfil automáticamente.
      //    Ver: supabase/schema.sql → función handle_new_user()
    } on AuthException catch (e) {
      throw app.AuthException(_translateAuthError(e.message));
    }
  }

  // ── Login email/password ──────────────────────────────────────────────────

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw app.AuthException(_translateAuthError(e.message));
    }
  }

  // ── Login social (OAuth) ──────────────────────────────────────────────────

  @override
  Future<void> signInWithGoogle() async {
    try {
      // OAuthProvider.google abre el navegador del sistema con la
      // pantalla de consentimiento de Google.
      // El redirect_url lleva de vuelta a la app (Deep Link).
      await _auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutterdemo://login-callback',
      );
    } on AuthException catch (e) {
      throw app.AuthException(_translateAuthError(e.message));
    }
  }

  @override
  Future<void> signInWithGithub() async {
    try {
      await _auth.signInWithOAuth(
        OAuthProvider.github,
        redirectTo: 'io.supabase.flutterdemo://login-callback',
      );
    } on AuthException catch (e) {
      throw app.AuthException(_translateAuthError(e.message));
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on AuthException catch (e) {
      throw app.AuthException(_translateAuthError(e.message));
    }
  }

  // ── Perfil ────────────────────────────────────────────────────────────────

  @override
  Future<UserProfile> getProfile() async {
    final userId = _requireUserId();

    try {
      // .select() con .eq() es el equivalente a:
      //   SELECT * FROM profiles WHERE id = '{userId}' LIMIT 1
      final data = await _supabase
          .from(SupabaseTables.profiles)
          .select()
          .eq('id', userId)
          .single(); // lanza si no existe exactamente 1 fila

      return UserProfileModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw app.DatabaseException(e.message);
    }
  }

  @override
  Future<UserProfile> updateProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    final userId = _requireUserId();

    try {
      // .update().eq().select().single() actualiza Y devuelve el registro.
      // Es el equivalente a: UPDATE profiles SET ... WHERE id = '...' RETURNING *
      final data = await _supabase
          .from(SupabaseTables.profiles)
          .update({
            if (fullName != null) 'full_name': fullName,
            if (avatarUrl != null) 'avatar_url': avatarUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .select()
          .single();

      return UserProfileModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw app.DatabaseException(e.message);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _requireUserId() {
    final userId = _auth.currentUser?.id;
    if (userId == null) throw const app.AuthException('No autenticado.');
    return userId;
  }

  /// Traduce mensajes de error de Supabase Auth al español.
  String _translateAuthError(String message) {
    final m = message.toLowerCase();
    if (m.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (m.contains('email already registered') || m.contains('already been registered')) {
      return 'Este correo ya está registrado.';
    }
    if (m.contains('password should be at least')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (m.contains('invalid email')) {
      return 'El correo electrónico no es válido.';
    }
    return message;
  }
}
