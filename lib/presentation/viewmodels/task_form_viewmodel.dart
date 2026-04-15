// lib/presentation/viewmodels/task_form_viewmodel.dart
//
// ─── VIEWMODEL — Crear / Editar tarea ────────────────────────────────────────
// Gestiona el estado del formulario y las operaciones .insert() / .update()
// junto con la subida de imagen de portada al Storage.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/i_storage_repository.dart';
import '../../domain/repositories/i_task_repository.dart';

class TaskFormViewModel extends ChangeNotifier {
  TaskFormViewModel({
    required ITaskRepository taskRepository,
    required IStorageRepository storageRepository,
    Task? existingTask, // null = crear nuevo | non-null = editar existente
  })  : _taskRepository = taskRepository,
        _storageRepository = storageRepository,
        _existingTask = existingTask {
    _initFromTask(existingTask);
  }

  final ITaskRepository _taskRepository;
  final IStorageRepository _storageRepository;
  final Task? _existingTask;

  // ── Estado del formulario ─────────────────────────────────────────────────

  late String title;
  late String description;
  late String status;
  late String priority;
  DateTime? dueDate;
  String? coverImageUrl;   // URL existente (al editar)
  File? coverImageFile;    // Archivo local nuevo (antes de subir)

  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isUploadingImage => _isUploadingImage;
  String? get errorMessage => _errorMessage;
  bool get isEditing => _existingTask != null;

  // ── Inicialización ────────────────────────────────────────────────────────

  void _initFromTask(Task? task) {
    title       = task?.title       ?? '';
    description = task?.description ?? '';
    status      = task?.status      ?? TaskStatus.todo;
    priority    = task?.priority    ?? TaskPriority.medium;
    dueDate     = task?.dueDate;
    coverImageUrl = task?.coverImageUrl;
  }

  // ── Setters del formulario ────────────────────────────────────────────────

  void setTitle(String v)       { title = v;       notifyListeners(); }
  void setDescription(String v) { description = v; notifyListeners(); }
  void setStatus(String v)      { status = v;       notifyListeners(); }
  void setPriority(String v)    { priority = v;     notifyListeners(); }
  void setDueDate(DateTime? v)  { dueDate = v;      notifyListeners(); }

  void setCoverImageFile(File file) {
    coverImageFile = file;
    notifyListeners();
  }

  // ── Guardar tarea (insert o update) ──────────────────────────────────────

  /// Guarda la tarea. Primero sube la imagen si hay una nueva seleccionada.
  /// Devuelve la tarea guardada, o null si hubo error.
  Future<Task?> save() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Subir imagen de portada si el usuario seleccionó una nueva
      String? finalCoverUrl = coverImageUrl;
      if (coverImageFile != null) {
        final taskId = _existingTask?.id ?? _tempId();
        finalCoverUrl = await _uploadCover(taskId, coverImageFile!);
      }

      // 2. Crear o actualizar la tarea en la BD
      final Task saved;
      if (_existingTask == null) {
        // ── CREATE: .insert()
        saved = await _taskRepository.createTask(
          title:         title,
          description:   description.isEmpty ? null : description,
          status:        status,
          priority:      priority,
          dueDate:       dueDate,
          coverImageUrl: finalCoverUrl,
        );
      } else {
        // ── UPDATE: .update()
        saved = await _taskRepository.updateTask(
          id:            _existingTask.id,
          title:         title,
          description:   description.isEmpty ? null : description,
          status:        status,
          priority:      priority,
          dueDate:       dueDate,
          coverImageUrl: finalCoverUrl,
        );
      }

      return saved;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<String> _uploadCover(String taskId, File file) async {
    _isUploadingImage = true;
    notifyListeners();

    try {
      return await _storageRepository.uploadCoverImage(
        taskId: taskId,
        filePath: file.path,
      );
    } finally {
      _isUploadingImage = false;
    }
  }

  /// Genera un ID temporal para la ruta del Storage cuando la tarea aún no tiene ID.
  /// Supabase asignará el ID real al insertar; moveremos el archivo después si es necesario.
  String _tempId() => 'temp_${DateTime.now().millisecondsSinceEpoch}';
}
