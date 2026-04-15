// lib/presentation/viewmodels/profile_viewmodel.dart
//
// ─── VIEWMODEL — Perfil de usuario ──────────────────────────────────────────
// Carga y permite editar el perfil del usuario autenticado.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/repositories/i_storage_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({
    required IAuthRepository authRepository,
    required IStorageRepository storageRepository,
  })  : _authRepository = authRepository,
        _storageRepository = storageRepository {
    loadProfile();
  }

  final IAuthRepository _authRepository;
  final IStorageRepository _storageRepository;

  // ── Estado observable ─────────────────────────────────────────────────────

  UserProfile? _profile;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  // ── Cargar perfil ─────────────────────────────────────────────────────────

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _authRepository.getProfile();
    } on AppException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Actualizar nombre ─────────────────────────────────────────────────────

  Future<void> updateFullName(String fullName) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      _profile = await _authRepository.updateProfile(fullName: fullName);
      _successMessage = 'Nombre actualizado correctamente.';
    } on AppException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ── Cambiar avatar ────────────────────────────────────────────────────────

  Future<void> updateAvatar(File imageFile) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Usamos el bucket de portadas también para el avatar
      // (podrías crear un bucket separado 'avatars' si prefieres)
      final avatarUrl = await _storageRepository.uploadCoverImage(
        taskId: 'avatars/${_profile?.id ?? 'unknown'}',
        filePath: imageFile.path,
      );

      _profile = await _authRepository.updateProfile(avatarUrl: avatarUrl);
      _successMessage = 'Foto de perfil actualizada.';
    } on AppException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ── Cerrar sesión ─────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _authRepository.signOut();
    // GoRouter detecta el cambio en authStateChanges y redirige al login
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
