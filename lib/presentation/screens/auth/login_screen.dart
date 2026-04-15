// lib/presentation/screens/auth/login_screen.dart
//
// ─── PANTALLA DE LOGIN ────────────────────────────────────────────────────────
// Demuestra:
//   • Formulario con validación del lado del cliente (GlobalKey<FormState>)
//   • Login con email/password → supabase.auth.signInWithPassword()
//   • Login OAuth con Google y GitHub → supabase.auth.signInWithOAuth()
//   • Uso del ViewModel con context.read / context.watch
//   • Manejo del estado de carga (isLoading) y errores (errorMessage)
//   • Navegación declarativa con GoRouter (go vs push)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // GlobalKey para acceder al estado del formulario (validar / resetear)
  final _formKey = GlobalKey<FormState>();

  // Controllers para leer el valor de cada campo
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    // SIEMPRE disponer los controllers para liberar memoria
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Acciones ──────────────────────────────────────────────────────────────

  Future<void> _signIn() async {
    // 1. Valida todos los campos del formulario
    if (!_formKey.currentState!.validate()) return;

    // 2. context.read: accede al ViewModel SIN suscribirse a cambios
    //    (no queremos reconstruir el widget al leer, solo al llamar un método)
    final vm = context.read<AuthViewModel>();
    final success = await vm.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    // 3. Si tuvo éxito, GoRouter redirige automáticamente por el auth guard.
    //    Si hubo error, el ViewModel expone errorMessage y la UI lo muestra.
    if (success && mounted) {
      context.go(AppRoutes.taskList);
    }
  }

  Future<void> _signInWithGoogle() async {
    final vm = context.read<AuthViewModel>();
    await vm.signInWithGoogle();
    // El deep link de OAuth devuelve el usuario; GoRouter redirige solo.
  }

  Future<void> _signInWithGithub() async {
    final vm = context.read<AuthViewModel>();
    await vm.signInWithGithub();
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // context.watch: SÍ suscribe al ViewModel → reconstruye cuando cambia isLoading
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),

                // ── Encabezado ─────────────────────────────────────────────
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Bienvenido de vuelta',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Inicia sesión para ver tus tareas',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                ),
                const SizedBox(height: 32),

                // ── Error global ───────────────────────────────────────────
                if (vm.errorMessage != null)
                  _ErrorBanner(
                    message: vm.errorMessage!,
                    onDismiss: vm.clearError,
                  ),

                // ── Campos ─────────────────────────────────────────────────
                AppTextField(
                  label: 'Correo electrónico',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  textInputAction: TextInputAction.next,
                  // Validación del lado del CLIENTE
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Ingresa tu correo';
                    }
                    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$')
                        .hasMatch(v.trim())) {
                      return 'Correo no válido';
                    }
                    return null; // null = válido
                  },
                ),
                const SizedBox(height: 16),

                AppTextField(
                  label: 'Contraseña',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: Icons.lock_outline,
                  textInputAction: TextInputAction.done,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // ── Botón principal ────────────────────────────────────────
                AppButton(
                  label: 'Iniciar sesión',
                  onPressed: _signIn,
                  isLoading: vm.isLoading,
                ),
                const SizedBox(height: 24),

                // ── Separador ──────────────────────────────────────────────
                const _OrDivider(),
                const SizedBox(height: 16),

                // ── OAuth ──────────────────────────────────────────────────
                AppButton(
                  label: 'Continuar con Google',
                  icon: Icons.g_mobiledata_rounded,
                  outlined: true,
                  onPressed: vm.isLoading ? null : _signInWithGoogle,
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Continuar con GitHub',
                  icon: Icons.code,
                  outlined: true,
                  onPressed: vm.isLoading ? null : _signInWithGithub,
                ),
                const SizedBox(height: 32),

                // ── Ir a registro ──────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('¿No tienes cuenta? '),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.register),
                      child: const Text(
                        'Regístrate',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Subwidgets ─────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close, size: 16, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'o continúa con',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF94A3B8),
                ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
