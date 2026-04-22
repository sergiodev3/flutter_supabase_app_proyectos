// lib/core/errors/app_exception.dart
//
// ─── PROPÓSITO ───────────────────────────────────────────────────────────────
// Excepciones tipadas de la aplicación.
//
// Patrón: los repositorios capturan errores de Supabase (PostgrestException,
// StorageException, etc.) y los convierten en AppException.
// Los ViewModels solo manejan AppException y exponen `String? errorMessage`
// a la UI sin revelar detalles internos de infraestructura.
// ─────────────────────────────────────────────────────────────────────────────

/// Excepción base de la aplicación.
/// Todas las excepciones de dominio heredan de esta clase.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

// ── Auth ──────────────────────────────────────────────────────────────────────

/// Error de autenticación: credenciales incorrectas, token expirado, etc.
class AuthException extends AppException {
  const AuthException(super.message);
}

/// El usuario intentó acceder a un recurso sin estar autenticado.
class UnauthenticatedException extends AppException {
  const UnauthenticatedException()
      : super('Debes iniciar sesión para continuar.');
}

// ── Base de datos ─────────────────────────────────────────────────────────────

/// Error al leer o escribir en la base de datos Supabase.
class DatabaseException extends AppException {
  const DatabaseException(super.message);
}

/// El recurso solicitado no existe en la base de datos.
class NotFoundException extends AppException {
  const NotFoundException(String resource) : super('No se encontró: $resource');
}

// ── Storage ───────────────────────────────────────────────────────────────────

/// Error al subir, descargar o eliminar un archivo en Supabase Storage.
class StorageException extends AppException {
  const StorageException(super.message);
}

// ── Red / General ─────────────────────────────────────────────────────────────

/// Error de red o error inesperado del servidor.
class NetworkException extends AppException {
  const NetworkException([super.message = 'Error de red. Revisa tu conexión.']);
}

/// Error desconocido. Se usa como fallback cuando no podemos clasificar el error.
class UnknownException extends AppException {
  const UnknownException([super.message = 'Ocurrió un error inesperado.']);
}
