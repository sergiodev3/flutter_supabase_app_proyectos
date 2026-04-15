// lib/presentation/viewmodels/task_detail_viewmodel.dart
//
// ─── VIEWMODEL — Detalle de tarea + Adjuntos ─────────────────────────────────
// Gestiona la vista de detalle: muestra la tarea, permite subir/eliminar
// adjuntos (documentos) y eliminar la tarea completa.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../core/errors/app_exception.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/i_storage_repository.dart';
import '../../domain/repositories/i_task_repository.dart';

class TaskDetailViewModel extends ChangeNotifier {
  TaskDetailViewModel({
    required ITaskRepository taskRepository,
    required IStorageRepository storageRepository,
    required String taskId,
  })  : _taskRepository = taskRepository,
        _storageRepository = storageRepository,
        _taskId = taskId {
    loadTask();
  }

  final ITaskRepository _taskRepository;
  final IStorageRepository _storageRepository;
  final String _taskId;

  // ── Estado observable ─────────────────────────────────────────────────────

  Task? _task;
  bool _isLoading = false;
  bool _isUploading = false;
  String? _errorMessage;
  String? _successMessage;

  Task? get task => _task;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  // ── Cargar tarea ──────────────────────────────────────────────────────────

  Future<void> loadTask() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _task = await _taskRepository.getTaskById(_taskId);
    } on AppException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Eliminar tarea ────────────────────────────────────────────────────────

  /// Elimina la tarea de la BD. Devuelve `true` si fue exitoso.
  /// La View puede usar este resultado para navegar hacia atrás.
  Future<bool> deleteTask() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _taskRepository.deleteTask(_taskId);
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Subir documento adjunto ───────────────────────────────────────────────

  /// Sube un documento al Storage y registra el adjunto en la BD.
  Future<void> uploadAttachment(File file) async {
    _isUploading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final fileName = p.basename(file.path);
      final fileType = p.extension(file.path).replaceAll('.', '').toLowerCase();
      final fileSize = await file.length();

      // 1. Sube el archivo físico al bucket 'task-documents' (privado)
      //    Devuelve la ruta en Storage, NO una URL
      final storagePath = await _storageRepository.uploadDocument(
        taskId:   _taskId,
        filePath: file.path,
        fileName: fileName,
      );

      // 2. Genera URL firmada temporal (1 hora) para guardar en BD
      //    Concepto clave: URLs firmadas expiran; el cliente debe pedirlas frescas
      final signedUrl = await _storageRepository.createSignedUrl(
        storagePath: storagePath,
      );

      // 3. Registra el adjunto en la tabla task_attachments
      final attachment = await _taskRepository.addAttachment(
        taskId:   _taskId,
        fileName: fileName,
        fileUrl:  signedUrl,
        fileType: fileType,
        fileSize: fileSize,
      );

      // 4. Actualiza la lista local
      if (_task != null) {
        _task = _task!.copyWith(
          attachments: [..._task!.attachments, attachment],
        );
      }

      _successMessage = 'Archivo "$fileName" subido correctamente.';
    } on AppException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  // ── Eliminar adjunto ──────────────────────────────────────────────────────

  Future<void> deleteAttachment(TaskAttachment attachment) async {
    try {
      // 1. Elimina el registro de la BD
      await _taskRepository.deleteAttachment(attachment.id);

      // 2. Elimina el archivo del Storage
      //    La URL firmada contiene la ruta; la parseamos para extraerla
      await _storageRepository.deleteDocument(attachment.fileUrl);

      // 3. Actualiza la lista local (optimistic update)
      if (_task != null) {
        _task = _task!.copyWith(
          attachments: _task!.attachments
              .where((a) => a.id != attachment.id)
              .toList(),
        );
        notifyListeners();
      }
    } on AppException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
