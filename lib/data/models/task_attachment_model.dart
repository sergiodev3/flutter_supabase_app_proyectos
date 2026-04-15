// lib/data/models/task_attachment_model.dart

import '../../domain/entities/task.dart';

/// Modelo de adjunto: serialización JSON ↔ [TaskAttachment].
class TaskAttachmentModel extends TaskAttachment {
  const TaskAttachmentModel({
    required super.id,
    required super.taskId,
    required super.userId,
    required super.fileName,
    required super.fileUrl,
    required super.fileType,
    required super.fileSize,
    required super.createdAt,
  });

  factory TaskAttachmentModel.fromJson(Map<String, dynamic> json) {
    return TaskAttachmentModel(
      id:        json['id']        as String,
      taskId:    json['task_id']   as String,
      userId:    json['user_id']   as String,
      fileName:  json['file_name'] as String,
      fileUrl:   json['file_url']  as String,
      fileType:  json['file_type'] as String,
      fileSize:  json['file_size'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'task_id':   taskId,
      'file_name': fileName,
      'file_url':  fileUrl,
      'file_type': fileType,
      'file_size': fileSize,
    };
  }
}
