// lib/presentation/viewmodels/auth_viewmodel.dart
//
// ─── VIEWMODEL — MVVM ────────────────────────────────────────────────────────
// El ViewModel es el intermediario entre la View (pantalla) y el Repositorio.
//
// Responsabilidades:
//   1. Exponer estado observable (isLoading, errorMessage, user)
//   2. Ejecutar lógica de negocio cuando la View llama un método
//   3. Notificar a la View cuando el estado cambia (notifyListeners)
//   4. NO conocer nada de Flutter UI (no usa BuildContext, Widgets, etc.)
//
// Patrón de uso en la pantalla:
//   context.watch<AuthViewModel>().isLoading  → reconstruye en cada cambio
//   context.read<AuthViewModel>().signIn(...)  → ejecuta acción sin reconstruir
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart'; // ChangeNotifier

import '../../core/errors/app_exception.dart';
import '../../domain/repositories/i_auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._authRepository);

  final IAuthRepository _authRepository;

  // ── Estado observable ─────────────────────────────────────────────────────

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── Acciones ──────────────────────────────────────────────────────────────

  /// Registra un nuevo usuario.
  /// Devuelve `true` si el registro fue exitoso.
  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
  }) => _run(() => _authRepository.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      ));

  /// Inicia sesión con email y contraseña.
  Future<bool> signIn({
    required String email,
    required String password,
  }) => _run(() => _authRepository.signInWithEmail(
        email: email,
        password: password,
      ));

  /// Inicia sesión con Google OAuth.
  Future<bool> signInWithGoogle() =>
      _run(() => _authRepository.signInWithGoogle());

  /// Inicia sesión con GitHub OAuth.
  Future<bool> signInWithGithub() =>
      _run(() => _authRepository.signInWithGithub());

  /// Cierra la sesión actual.
  Future<bool> signOut() => _run(() => _authRepository.signOut());

  /// Limpia el mensaje de error (útil cuando el usuario empieza a editar).
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Helper interno ────────────────────────────────────────────────────────

  /// Plantilla reutilizable para cualquier acción asíncrona:
  ///   1. Activa loading
  ///   2. Ejecuta la acción
  ///   3. Captura errores y los guarda en _errorMessage
  ///   4. Desactiva loading y notifica a la View
  ///
  /// Devuelve `true` si no hubo error, `false` si lo hubo.
  Future<bool> _run(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // ← La View ve isLoading = true → muestra spinner

    try {
      await action();
      return true;
    } on AppException catch (e) {
      // AppException = error controlado (credenciales, red, etc.)
      _errorMessage = e.message;
      return false;
    } catch (e) {
      // Error inesperado: lo registramos sin revelar detalles técnicos
      _errorMessage = 'Ocurrió un error inesperado. Intenta de nuevo.';
      debugPrint('AuthViewModel unexpected error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners(); // ← La View ve isLoading = false → oculta spinner
    }
  }
}
