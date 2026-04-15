// lib/presentation/screens/profile/profile_screen.dart
//
// ─── PANTALLA DE PERFIL ───────────────────────────────────────────────────────
// Demuestra:
//   • Leer datos del usuario autenticado (auth.currentUser + tabla profiles)
//   • Actualizar perfil con .update()
//   • Cambiar foto de perfil subiendo al Storage
//   • Cerrar sesión con signOut()
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Pre-carga el nombre al abrir la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = context.read<ProfileViewModel>().profile;
      if (profile?.fullName != null) {
        _nameController.text = profile!.fullName!;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 400,
    );
    if (xFile != null && mounted) {
      await context.read<ProfileViewModel>().updateAvatar(File(xFile.path));
    }
  }

  Future<void> _saveName() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<ProfileViewModel>().updateFullName(
          _nameController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();

    // Snackbars de feedback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (vm.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(vm.successMessage!),
              backgroundColor: AppColors.done),
        );
        vm.clearMessages();
      }
      if (vm.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(vm.errorMessage!),
              backgroundColor: AppColors.error),
        );
        vm.clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: vm.isLoading && vm.profile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ── Avatar ─────────────────────────────────────────────
                    _AvatarSection(
                      avatarUrl: vm.profile?.avatarUrl,
                      displayName: vm.profile?.displayName ?? '',
                      isLoading: vm.isSaving,
                      onTap: _pickAndUploadAvatar,
                    ),
                    const SizedBox(height: 32),

                    // ── Info de sesión (solo lectura) ──────────────────────
                    _InfoCard(
                      icon: Icons.email_outlined,
                      label: 'Correo electrónico',
                      value: vm.profile?.email ?? '—',
                    ),
                    const SizedBox(height: 8),
                    _InfoCard(
                      icon: Icons.fingerprint,
                      label: 'ID de usuario',
                      value: vm.profile?.id ?? '—',
                      monospace: true,
                    ),
                    const SizedBox(height: 24),

                    // ── Editar nombre ──────────────────────────────────────
                    AppTextField(
                      label: 'Nombre completo',
                      controller: _nameController,
                      prefixIcon: Icons.person_outline,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Ingresa tu nombre'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Guardar nombre',
                      onPressed: _saveName,
                      isLoading: vm.isSaving,
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),

                    // ── Cerrar sesión ──────────────────────────────────────
                    AppButton(
                      label: 'Cerrar sesión',
                      icon: Icons.logout,
                      outlined: true,
                      color: AppColors.error,
                      onPressed: () async {
                        await context.read<ProfileViewModel>().signOut();
                        // GoRouter detecta el cambio en authStateChanges
                        // y redirige automáticamente al login
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ── Subwidgets ─────────────────────────────────────────────────────────────────

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({
    required this.avatarUrl,
    required this.displayName,
    required this.isLoading,
    required this.onTap,
  });
  final String? avatarUrl;
  final String displayName;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            backgroundImage: avatarUrl != null
                ? CachedNetworkImageProvider(avatarUrl!)
                : null,
            child: avatarUrl == null
                ? Text(
                    displayName.isNotEmpty
                        ? displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          if (isLoading)
            const CircularProgressIndicator()
          else
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    this.monospace = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF94A3B8))),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF334155),
                  fontFamily: monospace ? 'monospace' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
