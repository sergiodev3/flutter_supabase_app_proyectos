// lib/domain/entities/user_profile.dart
//
// ─── CAPA DE DOMINIO ─────────────────────────────────────────────────────────
// Entidad que extiende los datos de `auth.users` (Supabase Auth)
// con campos adicionales guardados en la tabla pública `profiles`.
//
// ¿Por qué una tabla separada?
//   Supabase Auth gestiona auth.users internamente.
//   La tabla `profiles` es pública y se relaciona 1:1 con auth.users.
//   Esto permite añadir campos personalizados (nombre, avatar, bio…)
//   sin tocar la tabla de autenticación.
// ─────────────────────────────────────────────────────────────────────────────

/// Perfil público del usuario autenticado.
///
/// [id]        – Mismo UUID que `auth.users.id` (clave foránea)
/// [email]     – Correo electrónico (de Auth)
/// [fullName]  – Nombre completo ingresado en el perfil
/// [avatarUrl] – URL del avatar en Supabase Storage (bucket task-covers)
class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.createdAt,
    this.fullName,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final DateTime createdAt;

  /// Nombre a mostrar: usa fullName si existe, si no el prefijo del email.
  String get displayName => fullName ?? email.split('@').first;

  UserProfile copyWith({
    String? fullName,
    String? avatarUrl,
  }) {
    return UserProfile(
      id: id,
      email: email,
      createdAt: createdAt,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
