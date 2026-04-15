// lib/main.dart
//
// ─── PUNTO DE ENTRADA DE LA APLICACIÓN ───────────────────────────────────────
// Aquí se inicializa Supabase, se configuran los providers (inyección
// de dependencias) y se lanza la app.
//
// ORDEN DE INICIALIZACIÓN (importante):
//   1. WidgetsFlutterBinding.ensureInitialized() → necesario para usar plugins
//      antes de runApp()
//   2. Env.load() → carga el .env (necesario ANTES de inicializar Supabase)
//   3. Supabase.initialize() → establece la conexión con el proyecto Supabase
//   4. runApp() → lanza la UI
//
// INYECCIÓN DE DEPENDENCIAS con MultiProvider:
//   Los repositorios se crean UNA sola vez aquí y se exponen al árbol
//   de widgets. Los ViewModels los consumen en cada ruta via GoRouter.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/config/env.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/storage_repository.dart';
import 'data/repositories/task_repository.dart';
import 'domain/repositories/i_auth_repository.dart';
import 'domain/repositories/i_storage_repository.dart';
import 'domain/repositories/i_task_repository.dart';

Future<void> main() async {
  // 1. Necesario cuando usas plugins antes de runApp()
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Carga las variables del archivo .env (SUPABASE_URL, SUPABASE_ANON_KEY)
  await Env.load();

  // 3. Inicializa Supabase con las credenciales del .env
  //    Supabase SDK:
  //    • Gestiona el token JWT automáticamente (lo guarda en SecureStorage)
  //    • Refresca el token antes de que expire
  //    • Restaura la sesión al abrir la app
  await Supabase.initialize(
    url:       Env.supabaseUrl,
    anonKey:   Env.supabaseAnonKey,
    // Para debug: activa logs del cliente Supabase en consola
    debug: false,
  );

  // 4. Inicializa los datos de localización para formateo de fechas en español
  await initializeDateFormatting('es', null);

  // 5. Ejecuta la app
  runApp(const TaskBoardApp());
}

class TaskBoardApp extends StatelessWidget {
  const TaskBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Cliente de Supabase singleton (accesible en toda la app)
    final supabase = Supabase.instance.client;

    // ── Implementaciones concretas de los repositorios ─────────────────────
    // Se crean aquí (nivel raíz) para que vivan toda la vida de la app.
    // Se exponen como interfaces (IAuthRepository, etc.) para desacoplar
    // la lógica de negocio de la implementación concreta.
    final IAuthRepository    authRepository    = AuthRepository(supabase);
    final ITaskRepository    taskRepository    = TaskRepository(supabase);
    final IStorageRepository storageRepository = StorageRepository(supabase);

    // ── Router con guard de autenticación ──────────────────────────────────
    final router = createRouter(
      authRepository:    authRepository,
      taskRepository:    taskRepository,
      storageRepository: storageRepository,
    );

    // ── MultiProvider: expone los repositorios al árbol de widgets ─────────
    // Los ViewModels los acceden via context.read<IAuthRepository>(), etc.
    // NOTA: En esta app, los ViewModels reciben los repositorios directamente
    //       en el constructor (vía GoRouter), por lo que MultiProvider aquí
    //       sirve como documentación de las dependencias disponibles.
    return MultiProvider(
      providers: [
        Provider<IAuthRepository>.value(value: authRepository),
        Provider<ITaskRepository>.value(value: taskRepository),
        Provider<IStorageRepository>.value(value: storageRepository),
      ],
      child: MaterialApp.router(
        title: 'TaskBoard — Flutter + Supabase',

        // Tema visual definido en core/theme/app_theme.dart
        theme: AppTheme.light,

        // GoRouter maneja la navegación declarativamente
        routerConfig: router,

        // Oculta el banner "DEBUG" en el emulador
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
