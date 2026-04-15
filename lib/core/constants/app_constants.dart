// lib/core/constants/app_constants.dart
//
// ─── PROPÓSITO ───────────────────────────────────────────────────────────────
// Constantes globales de la aplicación: nombres de tablas Supabase,
// buckets de Storage, rutas de navegación y valores de UI.
//
// Al centralizar todo aquí evitamos "magic strings" dispersos por el código:
// si cambia un nombre, lo cambiamos en UN solo lugar.
// ─────────────────────────────────────────────────────────────────────────────

/// Nombres de tablas en la base de datos Supabase (PostgreSQL).
/// Coinciden exactamente con los nombres en tu schema.sql.
class SupabaseTables {
  SupabaseTables._();

  static const String profiles    = 'profiles';    // Perfil extendido del usuario
  static const String tasks       = 'tasks';        // Tareas del tablero
  static const String attachments = 'task_attachments'; // Adjuntos de tareas
}

/// Nombres de los buckets del Supabase Storage.
///
/// Enseña el concepto de ORGANIZACIÓN DEL STORAGE:
///   • task-covers   → imágenes de portada (jpg, png, webp)
///   • task-documents → documentos adjuntos (pdf, docx)
///
/// Separar buckets permite configurar reglas de acceso distintas
/// para imágenes públicas y documentos privados.
class StorageBuckets {
  StorageBuckets._();

  /// Imágenes de portada. Configurado como público → URL directa.
  static const String covers    = 'task-covers';

  /// Documentos adjuntos (PDF, DOCX…). Configurado como privado → URL firmada.
  static const String documents = 'task-documents';
}

/// Valores posibles para el campo `status` de una tarea.
/// Deben coincidir con el CHECK constraint en el schema.sql.
class TaskStatus {
  TaskStatus._();

  static const String todo       = 'todo';
  static const String inProgress = 'in_progress';
  static const String done       = 'done';

  static const List<String> all = [todo, inProgress, done];

  static String label(String status) => switch (status) {
    todo       => 'Pendiente',
    inProgress => 'En progreso',
    done       => 'Completada',
    _          => status,
  };
}

/// Valores posibles para el campo `priority` de una tarea.
class TaskPriority {
  TaskPriority._();

  static const String low    = 'low';
  static const String medium = 'medium';
  static const String high   = 'high';

  static const List<String> all = [low, medium, high];

  static String label(String priority) => switch (priority) {
    low    => 'Baja',
    medium => 'Media',
    high   => 'Alta',
    _      => priority,
  };
}

/// Rutas de navegación usadas por GoRouter.
/// Centralizar las rutas evita typos y facilita refactoring.
class AppRoutes {
  AppRoutes._();

  static const String splash    = '/';
  static const String login     = '/login';
  static const String register  = '/register';
  static const String taskList  = '/tasks';
  static const String taskNew   = '/tasks/new';
  static const String taskEdit  = '/tasks/:id/edit';
  static const String taskDetail = '/tasks/:id';
  static const String profile   = '/profile';
}
