// lib/data/models/task_model.dart
//
// ─── CAPA DE DATOS ───────────────────────────────────────────────────────────
// Los modelos son la representación de datos que viene de/va a Supabase.
// Saben cómo serializar/deserializar JSON (fromJson / toJson).
//
// Extienden las entidades del dominio para añadir esta lógica de conversión
// sin contaminar las entidades puras con código de infraestructura.
// ─────────────────────────────────────────────────────────────────────────────

import '../../domain/entities/task.dart';
import 'task_attachment_model.dart';

/// Modelo de tarea: extiende [Task] con conversión JSON ↔ Dart.
///
/// Los datos llegan de Supabase como Map<String, dynamic> (JSON):
/// ```json
/// {
///   "id": "abc-123",
///   "title": "Hacer login",
///   "status": "todo",
///   "priority": "high",
///   "user_id": "user-456",
///   "task_attachments": [...]
/// }
/// ```
class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.title,
    required super.userId,
    required super.status,
    required super.priority,
    required super.createdAt,
    required super.updatedAt,
    super.description,
    super.coverImageUrl,
    super.dueDate,
    super.attachments,
  });

  /// Deserializa un Map JSON (respuesta de Supabase) a un objeto [TaskModel].
  ///
  /// Notas sobre los nombres de campo:
  ///   • Supabase usa snake_case (user_id, cover_image_url…)
  ///   • Dart usa camelCase → convertimos aquí
  ///   • Las relaciones anidadas (task_attachments) llegan como listas
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    // Parsea la lista de adjuntos anidada (si existe)
    final attachmentsJson = json['task_attachments'] as List<dynamic>? ?? [];
    final attachments = attachmentsJson
        .map((a) => TaskAttachmentModel.fromJson(a as Map<String, dynamic>))
        .toList();

    return TaskModel(
      id:            json['id']              as String,
      title:         json['title']           as String,
      description:   json['description']     as String?,
      status:        json['status']          as String,
      priority:      json['priority']        as String,
      userId:        json['user_id']         as String,
      coverImageUrl: json['cover_image_url'] as String?,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      attachments: attachments,
    );
  }

  /// Serializa el modelo a Map para enviarlo a Supabase (.insert() / .update()).
  ///
  /// Notas:
  ///   • NO incluimos `id`, `user_id`, `created_at` ni `updated_at` en inserts
  ///     porque Supabase los genera automáticamente con DEFAULT en el schema.
  ///   • Sí los incluimos en updates cuando es necesario actualizar status, etc.
  Map<String, dynamic> toJson() {
    return {
      'title':           title,
      'description':     description,
      'status':          status,
      'priority':        priority,
      'cover_image_url': coverImageUrl,
      // Convierte DateTime a ISO 8601 string (formato que acepta PostgreSQL)
      'due_date':        dueDate?.toIso8601String().split('T').first,
    };
  }

  /// Map específico para INSERT (excluye campos autogenerados).
  Map<String, dynamic> toInsertJson() => toJson();

  /// Map específico para UPDATE (incluye solo los campos que queremos cambiar).
  Map<String, dynamic> toUpdateJson() => {
    ...toJson(),
    'updated_at': DateTime.now().toIso8601String(),
  };
}
