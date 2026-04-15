// lib/domain/repositories/i_task_repository.dart
//
// ─── CONTRATO (Interfaz) ─────────────────────────────────────────────────────
// Define las operaciones CRUD sobre tareas y el canal Realtime.
//
// CRUD en Supabase:
//   Create → .insert()
//   Read   → .select()
//   Update → .update()
//   Delete → .delete()
//
// Realtime: Supabase puede "escuchar" cambios en la tabla y notificar
// al cliente sin necesidad de refrescar manualmente.
// ─────────────────────────────────────────────────────────────────────────────

import '../entities/task.dart';

/// Contrato para operaciones sobre tareas.
abstract interface class ITaskRepository {
  // ── Lectura ──────────────────────────────────────────────────────────────────

  /// Obtiene todas las tareas del usuario autenticado.
  ///
  /// Internamente usa: `.select('*, task_attachments(*)')`
  /// El RLS de Supabase filtra automáticamente por `user_id = auth.uid()`.
  Future<List<Task>> getTasks();

  /// Obtiene una tarea específica por ID (incluyendo sus adjuntos).
  Future<Task> getTaskById(String id);

  // ── Escritura ────────────────────────────────────────────────────────────────

  /// Crea una nueva tarea en la base de datos.
  /// Internamente usa: `.insert(taskData)`
  Future<Task> createTask({
    required String title,
    String? description,
    required String status,
    required String priority,
    DateTime? dueDate,
    String? coverImageUrl,
  });

  /// Actualiza una tarea existente.
  /// Internamente usa: `.update(changes).eq('id', id)`
  Future<Task> updateTask({
    required String id,
    String? title,
    String? description,
    String? status,
    String? priority,
    DateTime? dueDate,
    String? coverImageUrl,
  });

  /// Elimina una tarea y sus adjuntos.
  /// Internamente usa: `.delete().eq('id', id)`
  Future<void> deleteTask(String id);

  // ── Adjuntos ─────────────────────────────────────────────────────────────────

  /// Agrega un registro de adjunto en la tabla `task_attachments`.
  Future<TaskAttachment> addAttachment({
    required String taskId,
    required String fileName,
    required String fileUrl,
    required String fileType,
    required int fileSize,
  });

  /// Elimina un adjunto de la base de datos.
  Future<void> deleteAttachment(String attachmentId);

  // ── Realtime ─────────────────────────────────────────────────────────────────

  /// Stream que emite la lista actualizada de tareas cada vez que
  /// hay un INSERT, UPDATE o DELETE en la tabla `tasks`.
  ///
  /// Concepto clave: Supabase Realtime usa WebSockets internamente.
  /// No necesitas "refrescar" la lista manualmente.
  Stream<List<Task>> watchTasks();
}
