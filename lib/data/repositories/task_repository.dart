// lib/data/repositories/task_repository.dart
//
// ─── IMPLEMENTACIÓN ──────────────────────────────────────────────────────────
// Implementación concreta de [ITaskRepository] usando Supabase Database.
//
// CONCEPTOS SUPABASE que se enseñan aquí:
//
//   📖 SELECT con relaciones anidadas:
//      .select('*, task_attachments(*)')
//      → PostgREST hace un JOIN automático usando la FK task_id
//
//   ✏️  INSERT y retorno del registro creado:
//      .insert(data).select().single()
//
//   🔄  UPDATE parcial:
//      .update({campos_a_cambiar}).eq('id', id).select().single()
//
//   🗑️  DELETE:
//      .delete().eq('id', id)
//
//   ⚡  Realtime:
//      .stream(primaryKey: ['id']).eq('user_id', userId)
//      → Emite la tabla completa cada vez que hay un cambio
//
//   🔒  RLS en acción:
//      No necesitas filtrar manualmente por user_id en SELECT/DELETE
//      porque la política RLS lo hace automáticamente.
//      En INSERT/UPDATE sí debes proveer user_id para que RLS lo acepte.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart' as app;
import '../../domain/entities/task.dart';
import '../../domain/repositories/i_task_repository.dart';
import '../models/task_attachment_model.dart';
import '../models/task_model.dart';

class TaskRepository implements ITaskRepository {
  TaskRepository(this._supabase);

  final SupabaseClient _supabase;

  String get _userId {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw const app.UnauthenticatedException();
    return id;
  }

  // ── SELECT ────────────────────────────────────────────────────────────────

  @override
  Future<List<Task>> getTasks() async {
    try {
      // .select('*, task_attachments(*)')
      //   *                  → todos los campos de `tasks`
      //   task_attachments(*) → relación 1:N → trae todos los adjuntos de cada tarea
      //
      // PostgREST genera automáticamente el JOIN usando la FK task_id.
      // Equivalente SQL:
      //   SELECT tasks.*, json_agg(task_attachments.*)
      //   FROM tasks
      //   LEFT JOIN task_attachments ON task_attachments.task_id = tasks.id
      //   -- RLS filtra automáticamente WHERE tasks.user_id = auth.uid()
      //   GROUP BY tasks.id
      //   ORDER BY tasks.created_at DESC
      final data = await _supabase
          .from(SupabaseTables.tasks)
          .select('*, ${SupabaseTables.attachments}(*)')
          .order('created_at', ascending: false);

      return (data as List)
          .map((json) => TaskModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw app.DatabaseException(e.message);
    }
  }

  @override
  Future<Task> getTaskById(String id) async {
    try {
      final data = await _supabase
          .from(SupabaseTables.tasks)
          .select('*, ${SupabaseTables.attachments}(*)')
          .eq('id', id)
          .single(); // Lanza error si no existe o hay más de 1 resultado

      return TaskModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw app.DatabaseException(e.message);
    }
  }

  // ── INSERT ────────────────────────────────────────────────────────────────

  @override
  Future<Task> createTask({
    required String title,
    String? description,
    required String status,
    required String priority,
    DateTime? dueDate,
    String? coverImageUrl,
  }) async {
    try {
      // .insert(data).select().single()
      //   insert()  → envía POST a la API PostgREST
      //   .select() → le dice a Supabase que devuelva el registro creado
      //   .single() → extrae el único objeto del array de respuesta
      //
      // user_id lo proveemos explícitamente para que RLS lo valide.
      // Supabase rechazará la inserción si user_id != auth.uid().
      final data = await _supabase
          .from(SupabaseTables.tasks)
          .insert({
            'title':           title,
            'description':     description,
            'status':          status,
            'priority':        priority,
            'user_id':         _userId,
            'cover_image_url': coverImageUrl,
            'due_date':        dueDate?.toIso8601String().split('T').first,
          })
          .select('*, ${SupabaseTables.attachments}(*)')
          .single();

      return TaskModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw app.DatabaseException(e.message);
    }
  }

  // ── UPDATE ────────────────────────────────────────────────────────────────

  @override
  Future<Task> updateTask({
    required String id,
    String? title,
    String? description,
    String? status,
    String? priority,
    DateTime? dueDate,
    String? coverImageUrl,
  }) async {
    try {
      // Solo enviamos los campos que realmente cambiaron (mapa dinámico).
      // Esto evita sobrescribir campos con null accidentalmente.
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
        if (title != null)        'title':           title,
        if (description != null)  'description':     description,
        if (status != null)       'status':          status,
        if (priority != null)     'priority':        priority,
        if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
        if (dueDate != null)      'due_date':
            dueDate.toIso8601String().split('T').first,
      };

      final data = await _supabase
          .from(SupabaseTables.tasks)
          .update(updates)
          .eq('id', id)
          .select('*, ${SupabaseTables.attachments}(*)')
          .single();

      return TaskModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw app.DatabaseException(e.message);
    }
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  @override
  Future<void> deleteTask(String id) async {
    try {
      // RLS garantiza que solo el dueño puede borrar su tarea.
      // ON DELETE CASCADE en la FK de task_attachments borra los adjuntos también.
      await _supabase
          .from(SupabaseTables.tasks)
          .delete()
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw app.DatabaseException(e.message);
    }
  }

  // ── Adjuntos ──────────────────────────────────────────────────────────────

  @override
  Future<TaskAttachment> addAttachment({
    required String taskId,
    required String fileName,
    required String fileUrl,
    required String fileType,
    required int fileSize,
  }) async {
    try {
      final data = await _supabase
          .from(SupabaseTables.attachments)
          .insert({
            'task_id':   taskId,
            'user_id':   _userId,
            'file_name': fileName,
            'file_url':  fileUrl,
            'file_type': fileType,
            'file_size': fileSize,
          })
          .select()
          .single();

      return TaskAttachmentModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw app.DatabaseException(e.message);
    }
  }

  @override
  Future<void> deleteAttachment(String attachmentId) async {
    try {
      await _supabase
          .from(SupabaseTables.attachments)
          .delete()
          .eq('id', attachmentId);
    } on PostgrestException catch (e) {
      throw app.DatabaseException(e.message);
    }
  }

  // ── Realtime ─────────────────────────────────────────────────────────────

  @override
  Stream<List<Task>> watchTasks() {
    // .stream() suscribe la app al canal Realtime de la tabla `tasks`.
    // Cada INSERT, UPDATE o DELETE emitirá la lista completa actualizada.
    //
    // IMPORTANTE: .stream() solo filtra por un campo a la vez.
    // Para relaciones complejas, usa .select() + pooling manual o
    // configura el canal Realtime de forma granular con .channel().
    return _supabase
        .from(SupabaseTables.tasks)
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId)
        .order('created_at', ascending: false)
        .map(
          (rows) => rows
              .map((json) => TaskModel.fromJson(json))
              .toList(),
        );
  }
}
