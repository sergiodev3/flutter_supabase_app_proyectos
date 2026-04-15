// lib/core/router/app_router.dart
//
// ─── ENRUTADOR DE LA APLICACIÓN ──────────────────────────────────────────────
// GoRouter implementa navegación declarativa en Flutter.
//
// CONCEPTOS CLAVE que se enseñan aquí:
//
//   🔒  Auth Guard (redirect):
//      GoRouter evalúa `redirect` en CADA navegación.
//      Si el usuario no está autenticado → redirige al login.
//      Si ya está autenticado e intenta ir al login → redirige a /tasks.
//      Esto evita acceso no autorizado sin escribir lógica repetida en cada pantalla.
//
//   ♻️  Refresh del router (listenable):
//      `refreshListenable` conecta el stream de auth al router.
//      Cada vez que el usuario hace login/logout, GoRouter re-evalúa
//      todos los redirects automáticamente.
//
//   📦  Inyección de dependencias por ruta:
//      Cada pantalla recibe su ViewModel inyectado con ChangeNotifierProvider.
//      Los repositorios vienen del contexto superior (MultiProvider en main.dart).
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import '../constants/app_constants.dart';
import '../../domain/entities/task.dart' as task_entity;
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/repositories/i_storage_repository.dart';
import '../../domain/repositories/i_task_repository.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/tasks/task_detail_screen.dart';
import '../../presentation/screens/tasks/task_form_screen.dart';
import '../../presentation/screens/tasks/task_list_screen.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/viewmodels/profile_viewmodel.dart';
import '../../presentation/viewmodels/task_detail_viewmodel.dart';
import '../../presentation/viewmodels/task_form_viewmodel.dart';
import '../../presentation/viewmodels/task_list_viewmodel.dart';

/// Crea y configura el [GoRouter] de la aplicación.
///
/// Recibe los repositorios como parámetros para inyectarlos en los ViewModels.
GoRouter createRouter({
  required IAuthRepository authRepository,
  required ITaskRepository taskRepository,
  required IStorageRepository storageRepository,
}) {
  // ── Listenable que conecta el stream de auth con GoRouter ─────────────────
  // Cada vez que el usuario inicia o cierra sesión, este notificador avisa
  // a GoRouter para que vuelva a evaluar los redirects.
  final authListenable = _AuthChangeListenable(authRepository);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authListenable,
    debugLogDiagnostics: true, // Imprime navegación en consola durante desarrollo

    // ── Guard de autenticación ─────────────────────────────────────────────
    redirect: (context, state) {
      final user = authRepository.currentUser;
      final isAuthenticated = user != null;
      final location = state.matchedLocation;

      // Rutas que no requieren autenticación
      final isPublicRoute = location == AppRoutes.login ||
          location == AppRoutes.register ||
          location == AppRoutes.splash;

      if (!isAuthenticated && !isPublicRoute) {
        // Usuario no autenticado intenta acceder a ruta protegida → login
        return AppRoutes.login;
      }

      if (isAuthenticated && isPublicRoute && location != AppRoutes.splash) {
        // Usuario ya autenticado intenta ir al login → lista de tareas
        return AppRoutes.taskList;
      }

      return null; // null = sin redirección, continúa normalmente
    },

    // ── Rutas ──────────────────────────────────────────────────────────────
    routes: [
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),

      // Login
      GoRoute(
        path: AppRoutes.login,
        builder: (context, _) => ChangeNotifierProvider(
          create: (_) => AuthViewModel(authRepository),
          child: const LoginScreen(),
        ),
      ),

      // Registro
      GoRoute(
        path: AppRoutes.register,
        builder: (context, _) => ChangeNotifierProvider(
          create: (_) => AuthViewModel(authRepository),
          child: const RegisterScreen(),
        ),
      ),

      // Lista de tareas (pantalla principal)
      GoRoute(
        path: AppRoutes.taskList,
        builder: (context, _) => ChangeNotifierProvider(
          create: (_) => TaskListViewModel(taskRepository),
          child: const TaskListScreen(),
        ),
      ),

      // Nueva tarea
      GoRoute(
        path: AppRoutes.taskNew,
        builder: (context, _) => ChangeNotifierProvider(
          create: (_) => TaskFormViewModel(
            taskRepository: taskRepository,
            storageRepository: storageRepository,
          ),
          child: const TaskFormScreen(),
        ),
      ),

      // Detalle de tarea
      GoRoute(
        path: AppRoutes.taskDetail,
        builder: (context, state) {
          final taskId = state.pathParameters['id']!;
          return ChangeNotifierProvider(
            create: (_) => TaskDetailViewModel(
              taskRepository: taskRepository,
              storageRepository: storageRepository,
              taskId: taskId,
            ),
            child: TaskDetailScreen(taskId: taskId),
          );
        },
      ),

      // Editar tarea
      // La tarea existente se pasa como `extra` desde TaskDetailScreen:
      //   context.push(AppRoutes.taskEdit.replaceFirst(':id', id), extra: task)
      GoRoute(
        path: AppRoutes.taskEdit,
        builder: (context, state) {
          // state.extra contiene la Task pasada desde la pantalla de detalle.
          // Usar `extra` evita una segunda consulta a la BD.
          final existingTask = state.extra as task_entity.Task?;
          return ChangeNotifierProvider(
            create: (_) => TaskFormViewModel(
              taskRepository: taskRepository,
              storageRepository: storageRepository,
              existingTask: existingTask,
            ),
            child: TaskFormScreen(existingTask: existingTask),
          );
        },
      ),

      // Perfil
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, _) => ChangeNotifierProvider(
          create: (_) => ProfileViewModel(
            authRepository: authRepository,
            storageRepository: storageRepository,
          ),
          child: const ProfileScreen(),
        ),
      ),
    ],
  );
}

// ── Helper: conecta Stream<User?> con Listenable ──────────────────────────────

/// Convierte el stream de cambios de autenticación en un [ChangeNotifier]
/// que GoRouter puede escuchar a través de [refreshListenable].
class _AuthChangeListenable extends ChangeNotifier {
  _AuthChangeListenable(IAuthRepository authRepository) {
    // Suscribe al stream de auth. Cada emisión notifica a GoRouter.
    _subscription = authRepository.authStateChanges.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<User?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
