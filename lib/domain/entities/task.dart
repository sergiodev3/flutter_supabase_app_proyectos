// lib/domain/entities/task.dart
//
// ─── CAPA DE DOMINIO ─────────────────────────────────────────────────────────
// Las entidades son los objetos de negocio PUROS de la aplicación.
// No dependen de Supabase, Flutter ni ninguna librería externa.
// Son clases Dart simples e inmutables.
//
// Patrón MVVM:  View → ViewModel → Repository → [Supabase]
//               Las entidades viajan entre Repository y ViewModel.
// ─────────────────────────────────────────────────────────────────────────────

/// Entidad principal: representa una tarea en el tablero.
///
/// Campos importantes para la clase:
///   • [id]             – UUID generado por Supabase (uuid_generate_v4())
///   • [userId]         – ID del usuario dueño (aplicado en RLS)
///   • [status]         – Estado actual: todo | in_progress | done
///   • [priority]       – Importancia: low | medium | high
///   • [coverImageUrl]  – URL pública en bucket 'task-covers'
///   • [attachments]    – Lista de archivos adjuntos (PDFs, DOCX…)
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.userId,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.coverImageUrl,
    this.dueDate,
    this.attachments = const [],
  });

  final String id;
  final String title;
  final String? description;
  final String status;    // Usa las constantes de TaskStatus
  final String priority;  // Usa las constantes de TaskPriority
  final String userId;
  final String? coverImageUrl;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TaskAttachment> attachments;

  /// Crea una copia modificada de la tarea.
  /// Útil en el ViewModel para actualizar campos individuales sin mutar el objeto.
  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    String? priority,
    String? userId,
    String? coverImageUrl,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TaskAttachment>? attachments,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      userId: userId ?? this.userId,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachments: attachments ?? this.attachments,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Task && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Entidad que representa un archivo adjunto a una tarea.
///
/// Se almacena en la tabla `task_attachments` y el archivo
/// físico vive en el bucket `task-documents` de Supabase Storage.
class TaskAttachment {
  const TaskAttachment({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    required this.createdAt,
  });

  final String id;
  final String taskId;
  final String userId;
  final String fileName;  // Nombre original del archivo
  final String fileUrl;   // URL firmada o pública del archivo
  final String fileType;  // 'pdf', 'docx', 'xlsx'…
  final int fileSize;     // En bytes
  final DateTime createdAt;

  /// Devuelve el tamaño en formato legible: "1.2 MB", "340 KB"
  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
